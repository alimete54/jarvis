import 'dart:async';

import 'package:flutter/foundation.dart';

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

  ChatViewModel({required this.settings, required this.executor, required this.speech}) {
    client = LLMClient(settings: settings, executor: executor);
  }

  bool get busy => _busy;
  bool get speakAfterReply => _speakAfterReply;
  bool get listening => _listening;

  set speakAfterReply(bool v) {
    _speakAfterReply = v;
    notifyListeners();
  }

  List<ChatMessage> get _llmHistory => entries
      .where((e) => !e.isError)
      .map((e) => e.role == 'user'
          ? ChatMessage.user(e.text)
          : ChatMessage.assistant(e.text))
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

  void clear() {
    entries.clear();
    notifyListeners();
  }
}
