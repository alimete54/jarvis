import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jarvis/services/ai/llm_client.dart';
import 'package:jarvis/services/ai/speech_service.dart';
import 'package:jarvis/services/ai/tool_executor.dart';
import 'package:jarvis/services/settings_service.dart';

class ChatEntry {
  final String role;
  final String text;
  final List<ToolInvocation> tools;
  final DateTime time;
  final bool isError;

  ChatEntry.user(String text)
      : role = 'user',
        text = text,
        tools = const [],
        time = DateTime.now(),
        isError = false;

  ChatEntry.assistant(String text, {this.tools = const []})
      : role = 'assistant',
        text = text,
        time = DateTime.now(),
        isError = false;

  ChatEntry.error(String text)
      : role = 'assistant',
        text = text,
        tools = const [],
        time = DateTime.now(),
        isError = true;
}

class ChatViewModel extends ChangeNotifier {
  final SettingsService settings;
  final ToolExecutor executor;
  final SpeechService speech;

  late final LLMClient client;

  final List<ChatEntry> entries = [];
  final ValueNotifier<String> liveTranscript = ValueNotifier('');

  bool _busy = false;
  bool _speakAfterReply = true;
  bool _listening = false;
  bool _wakeRunning = false;

  ChatViewModel({required this.settings, required this.executor, required this.speech}) {
    client = LLMClient(settings: settings, executor: executor);
    _restoreHistory();
  }

  bool get busy => _busy;
  bool get speakAfterReply => _speakAfterReply;
  bool get listening => _listening;
  bool get wakeRunning => _wakeRunning;

  set speakAfterReply(bool v) {
    _speakAfterReply = v;
    notifyListeners();
  }

  // ─────────── Geçmiş kalıcılığı (hafıza) ───────────

  static const _kHistory = 'jarvis.chat_history';
  static const _maxPersisted = 60;

  Future<void> _restoreHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistory);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      entries.addAll(list.map((e) {
        final m = e as Map<String, dynamic>;
        final role = m['role'] as String? ?? 'user';
        final text = m['text'] as String? ?? '';
        final isError = m['isError'] == true;
        if (role == 'user') return ChatEntry.user(text);
        if (isError) return ChatEntry.error(text);
        return ChatEntry.assistant(text);
      }));
      notifyListeners();
    } catch (e) {
      debugPrint('Geçmiş yüklenemedi: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final recent = entries.length > _maxPersisted
          ? entries.sublist(entries.length - _maxPersisted)
          : entries;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kHistory,
        jsonEncode(recent
            .map((e) => {
                  'role': e.role,
                  'text': e.text,
                  'time': e.time.toIso8601String(),
                  'isError': e.isError,
                })
            .toList()),
      );
    } catch (e) {
      debugPrint('Geçmiş kaydedilemedi: $e');
    }
  }

  // ─────────── Mesajlaşma ───────────

  List<ChatMessage> get _llmHistory => entries
      .where((e) => !e.isError)
      .map((e) => e.role == 'user'
          ? ChatMessage.user(e.text)
          : ChatMessage.assistant(e.text))
      .toList()
      .reversed
      .take(20)
      .toList()
      .reversed
      .toList();

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;

    entries.add(ChatEntry.user(trimmed));
    _busy = true;
    liveTranscript.value = '';
    notifyListeners();

    try {
      final result = await client.chat(
        _llmHistory,
        onToolCall: (tool) => notifyListeners(),
      );
      entries.add(ChatEntry.assistant(result.text, tools: result.toolLog));
    } on LLMException catch (e) {
      entries.add(ChatEntry.error(e.message));
    } catch (e) {
      entries.add(ChatEntry.error('Beklenmeyen hata: $e'));
    }

    _busy = false;
    unawaited(_persist());
    notifyListeners();

    final last = entries.last;
    if (_speakAfterReply && last.role == 'assistant' && !last.isError) {
      unawaited(speech.speak(last.text));
    }
  }

  Future<void> toggleListening() async {
    if (_listening) {
      await _finishListening();
      return;
    }
    if (_busy) return;
    _listening = true;
    liveTranscript.value = 'Dinleniyor...';
    notifyListeners();
    try {
      await speech.startListening(onPartial: (partial) {
        liveTranscript.value = partial;
        notifyListeners();
      });
    } catch (e) {
      liveTranscript.value = '';
      _listening = false;
      notifyListeners();
    }
  }

  Future<void> _finishListening() async {
    final live = liveTranscript.value;
    _listening = false;
    notifyListeners();
    try {
      final transcript = await speech.stopListening();
      liveTranscript.value = '';
      final text = transcript.isNotEmpty ? transcript : live;
      if (text.isNotEmpty && text != 'Dinleniyor...') {
        await send(text);
      } else {
        liveTranscript.value = 'Sizi duyamadım, tekrar deneyin.';
        Timer(const Duration(seconds: 3), () {
          if (liveTranscript.value == 'Sizi duyamadım, tekrar deneyin.') {
            liveTranscript.value = '';
          }
        });
        notifyListeners();
      }
    } catch (e) {
      liveTranscript.value = '';
      notifyListeners();
    }
  }

  Future<void> cancelListening() async {
    _listening = false;
    liveTranscript.value = '';
    await speech.cancelListening();
    notifyListeners();
  }

  Future<void> stopSpeaking() => speech.stopSpeaking();

  // ─────────── Uyandırma kelimesi ───────────

  bool get wakeWordSupported =>
      settings.wakeWordEnabled && settings.sttMode == STTMode.onDevice;

  Future<void> startWakeWord() async {
    if (!wakeWordSupported || _wakeRunning || _busy) return;
    _wakeRunning = true;
    notifyListeners();
    await speech.startWakeWord(onWake: _handleWakeCommand);
  }

  Future<void> stopWakeWord() async {
    if (!_wakeRunning) return;
    _wakeRunning = false;
    notifyListeners();
    await speech.stopWakeWord();
  }

  Future<void> _handleWakeCommand(String command) async {
    if (command.isNotEmpty) {
      await send(command);
    }
    if (_wakeRunning) {
      await speech.startWakeWord(onWake: _handleWakeCommand);
    }
  }

  void clear() {
    entries.clear();
    unawaited(_persist());
    notifyListeners();
  }
}
