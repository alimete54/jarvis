import 'package:flutter/foundation.dart';

import 'package:jarvis/services/ai/speech_service.dart';
import 'package:jarvis/services/ai/tool_executor.dart';
import 'package:jarvis/services/settings_service.dart';

import 'chat_viewmodel.dart';

class JARVISViewModel extends ChangeNotifier {
  final SettingsService settings;
  final ToolExecutor executor;
  late final SpeechService speech;
  late final ChatViewModel chat;

  bool _ready = false;

  bool get ready => _ready;

  JARVISViewModel()
      : settings = SettingsService(),
        executor = ToolExecutor();

  /// Kurulum: ayarları yükle, servisleri bağla.
  Future<void> init() async {
    await settings.load();
    speech = SpeechService(settings: settings);
    chat = ChatViewModel(settings: settings, executor: executor, speech: speech);
    _ready = true;
    notifyListeners();
  }

  void disposeAll() {
    speech.dispose();
    executor.dispose();
  }
}
