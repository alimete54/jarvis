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
  String _partial = '';
  final ValueNotifier<SpeakingState> state = ValueNotifier(SpeakingState.idle);

  bool get isOnDeviceSTT => settings.sttMode == STTMode.onDevice;

  Future<bool> _ensureSTT() async {
    if (!_sttReady) {
      _sttReady = await _stt.initialize(
        onStatus: (_) {},
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
        await _stt.listen(
          localeId: 'tr_TR',
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
    if (isOnDeviceSTT) {
      await _stt.cancel();
    } else if (_recording) {
      await _recorder.stop();
      _recording = false;
    }
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
    await _tts.setLanguage('tr-TR');
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
    _stt.cancel();
    _tts.stop();
    _recorder.dispose();
    _player.dispose();
    state.dispose();
  }
}
