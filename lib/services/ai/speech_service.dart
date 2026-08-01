import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:jarvis/services/settings_service.dart';

enum SpeakingState { idle, listening, speaking, processing }

class SpeechService {
  final SettingsService settings;

  SpeechService({required this.settings});

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _sttReady = false;
  bool _recording = false;
  bool _wakeActive = false;
  bool _capturingCommand = false;
  String _partial = '';
  void Function(String command)? _onWake;
  final ValueNotifier<SpeakingState> state = ValueNotifier(SpeakingState.idle);

  bool get isOnDeviceSTT => settings.sttMode == STTMode.onDevice;

  /// Cihazda Türkçe varsa tr_TR, yoksa sistem varsayılanını kullanır.
  Future<String?> _sttLocale() async {
    try {
      final list = await _stt.locales();
      for (final l in list) {
        if (l.localeId == 'tr_TR') return 'tr_TR';
      }
    } catch (_) {}
    return null;
  }

  void Function(String status)? _statusHandler;

  Future<bool> _ensureSTT() async {
    if (!_sttReady) {
      _sttReady = await _stt.initialize(
        onStatus: (s) => _statusHandler?.call(s),
        onError: (e) => debugPrint('STT hatası: $e'),
      );
    }
    return _sttReady;
  }

  Future<bool> _ensureRecorder() async {
    return _recorder.hasPermission();
  }

  /// Dinlemeyi başlatır. [onPartial] her ara sonuçta çağrılır (canlı transkript).
  Future<String?> startListening({void Function(String partial)? onPartial}) async {
    if (_recording) return null;
    _setState(SpeakingState.listening);
    _partial = '';

    try {
      if (isOnDeviceSTT) {
        if (!await _ensureSTT()) {
          throw Exception('Mikrofon/speech izni verilmedi. Ayarlardan STT modunu değiştirin.');
        }
        _statusHandler = null;
        await _stt.listen(
          localeId: await _sttLocale(),
          listenMode: ListenMode.dictation,
          onResult: (SpeechRecognitionResult result) {
            _partial = result.recognizedWords;
            onPartial?.call(_partial);
          },
        );
        return null; // sonuç stopListening'de alınır
      } else {
        if (!await _ensureRecorder()) {
          throw Exception('Mikrofon izni verilmedi.');
        }
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/jarvis_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
          path: path,
        );
        _recording = true;
        return null;
      }
    } catch (e) {
      _setState(SpeakingState.idle);
      rethrow;
    }
  }

  /// Dinlemeyi durdurur ve transkripti döndürür.
  Future<String> stopListening() async {
    try {
      if (isOnDeviceSTT) {
        await _stt.stop();
        return _partial;
      } else {
        if (!_recording) return _partial;
        final path = await _recorder.stop();
        _recording = false;
        if (path == null) return '';
        return settings.sttMode == STTMode.whisper
            ? await _transcribeWhisper(path)
            : await _transcribeGemini(path);
      }
    } finally {
      _setState(SpeakingState.idle);
    }
  }

  Future<void> cancelListening() async {
    _statusHandler = null;
    if (isOnDeviceSTT) {
      await _stt.cancel();
    } else if (_recording) {
      await _recorder.stop();
      _recording = false;
    }
    _setState(SpeakingState.idle);
  }

  // ─────────── Uyandırma kelimesi ("Jarvis") ───────────

  /// Sürekli dinler; "jarvis" duyunca [onWake]'i komutla çağırır.
  Future<void> startWakeWord({required void Function(String command) onWake}) async {
    _onWake = onWake;
    _wakeActive = true;
    _capturingCommand = false;
    await _wakeListen();
  }

  Future<void> _wakeListen() async {
    if (!_wakeActive || _capturingCommand) return;
    try {
      if (!await _ensureSTT()) return;
      _statusHandler = (status) {
        if (_wakeActive &&
            !_capturingCommand &&
            (status == 'done' || status == 'notListening')) {
          Future.delayed(const Duration(milliseconds: 400), _wakeListen);
        }
      };
      await _stt.listen(
        localeId: await _sttLocale(),
        listenMode: ListenMode.confirmation,
        onResult: (SpeechRecognitionResult r) {
          if (!_wakeActive || _capturingCommand) return;
          final words = r.recognizedWords.toLowerCase();
          if (words.contains('jarvis')) {
            unawaited(_wakeDetected(words));
          }
        },
      );
    } catch (e) {
      debugPrint('Uyandırma dinleme hatası: $e');
      Future.delayed(const Duration(milliseconds: 800), _wakeListen);
    }
  }

  Future<void> _wakeDetected(String utterance) async {
    _wakeActive = false;
    _statusHandler = null;
    try {
      await _stt.stop();
    } catch (_) {}
    final command = utterance
        .replaceAll(RegExp(r'^(hey|tamam|peki|evet|bey)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'jarvis\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zçğıöşü0-9 ]+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (command.isEmpty) {
      _capturingCommand = true;
      _partial = '';
      _statusHandler = (status) {
        if (_capturingCommand &&
            (status == 'done' || status == 'notListening')) {
          _capturingCommand = false;
          _statusHandler = null;
          unawaited(_deliverCommand(_partial));
        }
      };
      try {
        await _stt.listen(
          localeId: await _sttLocale(),
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 2),
          onResult: (SpeechRecognitionResult r) => _partial = r.recognizedWords,
        );
      } catch (e) {
        _capturingCommand = false;
        _statusHandler = null;
        debugPrint('Komut dinleme hatası: $e');
      }
      return;
    }
    await _deliverCommand(command);
  }

  Future<void> _deliverCommand(String command) async {
    final cb = _onWake;
    _onWake = null;
    if (cb != null && command.isNotEmpty) {
      debugPrint('Uyandırma komutu: $command');
      cb(command);
    }
  }

  Future<void> stopWakeWord() async {
    _wakeActive = false;
    _capturingCommand = false;
    _onWake = null;
    _statusHandler = null;
    try {
      await _stt.cancel();
    } catch (_) {}
    _setState(SpeakingState.idle);
  }

  Future<String> _transcribeWhisper(String path) async {
    if (settings.openAIKey.isEmpty) {
      throw Exception('Whisper için OpenAI anahtarı gerekli. Ayarlardan ekleyin.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer ${settings.openAIKey}';
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = 'tr';
    request.files.add(await http.MultipartFile.fromPath('file', path));
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final body = jsonDecode(await streamed.stream.bytesToString());
    if (streamed.statusCode >= 400) {
      throw Exception('Whisper hatası: ${body['error']?['message'] ?? body}');
    }
    return (body['text'] as String? ?? '').trim();
  }

  Future<String> _transcribeGemini(String path) async {
    if (settings.geminiKey.isEmpty) {
      throw Exception('Gemini ses modu için Gemini anahtarı gerekli.');
    }
    final bytes = await File(path).readAsBytes();
    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${settings.geminiKey}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'inlineData': {
                      'mimeType': 'audio/wav',
                      'data': base64Encode(bytes),
                    },
                  },
                  {'text': 'Bu ses kaydındaki konuşmayı olduğu gibi yaz.'},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 90));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List? ?? [];
    if (candidates.isEmpty) {
      final err = body['error'] as Map<String, dynamic>?;
      throw Exception('Gemini ses hatası: ${err?['message'] ?? 'yanıt yok'}');
    }
    final parts = ((candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?)?['parts'] as List? ??
        [];
    return parts
        .map((p) => (p as Map<String, dynamic>)['text'] as String?)
        .whereType<String>()
        .join()
        .trim();
  }

  /// Konuşma yanıtı. Ayara göre sistem sesi veya OpenAI TTS.
  Future<void> speak(String text) async {
    _setState(SpeakingState.speaking);
    try {
      if (settings.ttsMode == TTSMode.openai && settings.openAIKey.isNotEmpty) {
        await _speakOpenAI(text);
      } else {
        await _speakSystem(text);
      }
    } catch (e) {
      await _speakSystem(text);
    } finally {
      _setState(SpeakingState.idle);
    }
  }

  Future<void> _speakSystem(String text) async {
    try {
      final ok = await _tts.setLanguage('tr-TR');
      if (ok != 1) {
        await _tts.setLanguage('tr');
      }
    } catch (_) {
      try {
        await _tts.setLanguage('tr');
      } catch (_) {}
    }
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.speak(text);
  }

  Future<void> _speakOpenAI(String text) async {
    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/audio/speech'),
          headers: {
            'Authorization': 'Bearer ${settings.openAIKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini-tts',
            'voice': 'onyx',
            'input': text,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode >= 400) {
      throw Exception('TTS hatası (${response.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/jarvis_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
    await File(path).writeAsBytes(response.bodyBytes);
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    await _player.stop();
    _setState(SpeakingState.idle);
  }

  void _setState(SpeakingState s) {
    state.value = s;
  }

  void dispose() {
    _wakeActive = false;
    _capturingCommand = false;
    try {
      _stt.cancel();
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}
    try {
      _recorder.dispose();
    } catch (_) {}
    try {
      _player.dispose();
    } catch (_) {}
    state.dispose();
  }
}
