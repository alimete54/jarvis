import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AIProvider { openai, anthropic, gemini }

enum STTMode { onDevice, whisper, geminiAudio }

enum TTSMode { system, openai }

class SettingsService extends ChangeNotifier {
  static const _kProvider = 'jarvis.provider';
  static const _kOpenAIKey = 'jarvis.openai_key';
  static const _kAnthropicKey = 'jarvis.anthropic_key';
  static const _kGeminiKey = 'jarvis.gemini_key';
  static const _kOpenAIModel = 'jarvis.openai_model';
  static const _kAnthropicModel = 'jarvis.anthropic_model';
  static const _kGeminiModel = 'jarvis.gemini_model';
  static const _kSTTMode = 'jarvis.stt_mode';
  static const _kTTSMode = 'jarvis.tts_mode';
  static const _kWakeWordEnabled = 'jarvis.wake_word';
  static const _kUserName = 'jarvis.user_name';

  AIProvider _provider = AIProvider.openai;
  String _openAIKey = '';
  String _anthropicKey = '';
  String _geminiKey = '';
  String _openAIModel = 'gpt-4o-mini';
  String _anthropicModel = 'claude-sonnet-4-20250514';
  String _geminiModel = 'gemini-2.0-flash';
  STTMode _sttMode = STTMode.onDevice;
  TTSMode _ttsMode = TTSMode.system;
  bool _wakeWordEnabled = false;
  String _userName = 'Efendim';

  AIProvider get provider => _provider;
  String get openAIKey => _openAIKey;
  String get anthropicKey => _anthropicKey;
  String get geminiKey => _geminiKey;
  String get openAIModel => _openAIModel;
  String get anthropicModel => _anthropicModel;
  String get geminiModel => _geminiModel;
  STTMode get sttMode => _sttMode;
  TTSMode get ttsMode => _ttsMode;
  bool get wakeWordEnabled => _wakeWordEnabled;
  String get userName => _userName;

  String get activeKey {
    switch (_provider) {
      case AIProvider.openai:
        return _openAIKey;
      case AIProvider.anthropic:
        return _anthropicKey;
      case AIProvider.gemini:
        return _geminiKey;
    }
  }

  String get activeModel {
    switch (_provider) {
      case AIProvider.openai:
        return _openAIModel;
      case AIProvider.anthropic:
        return _anthropicModel;
      case AIProvider.gemini:
        return _geminiModel;
    }
  }

  bool get isConfigured => activeKey.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _provider = AIProvider.values[prefs.getInt(_kProvider) ?? 0];
    _openAIKey = prefs.getString(_kOpenAIKey) ?? '';
    _anthropicKey = prefs.getString(_kAnthropicKey) ?? '';
    _geminiKey = prefs.getString(_kGeminiKey) ?? '';
    _openAIModel = prefs.getString(_kOpenAIModel) ?? _openAIModel;
    _anthropicModel = prefs.getString(_kAnthropicModel) ?? _anthropicModel;
    _geminiModel = prefs.getString(_kGeminiModel) ?? _geminiModel;
    _sttMode = STTMode.values[prefs.getInt(_kSTTMode) ?? 0];
    _ttsMode = TTSMode.values[prefs.getInt(_kTTSMode) ?? 0];
    _wakeWordEnabled = prefs.getBool(_kWakeWordEnabled) ?? false;
    _userName = prefs.getString(_kUserName) ?? 'Efendim';
    notifyListeners();
  }

  void setProvider(AIProvider p) async {
    _provider = p;
    await _saveInt(_kProvider, p.index);
  }

  void setOpenAIKey(String v) async {
    _openAIKey = v.trim();
    await _saveString(_kOpenAIKey, _openAIKey);
  }

  void setAnthropicKey(String v) async {
    _anthropicKey = v.trim();
    await _saveString(_kAnthropicKey, _anthropicKey);
  }

  void setGeminiKey(String v) async {
    _geminiKey = v.trim();
    await _saveString(_kGeminiKey, _geminiKey);
  }

  void setModel(AIProvider p, String model) async {
    switch (p) {
      case AIProvider.openai:
        _openAIModel = model;
        await _saveString(_kOpenAIModel, model);
      case AIProvider.anthropic:
        _anthropicModel = model;
        await _saveString(_kAnthropicModel, model);
      case AIProvider.gemini:
        _geminiModel = model;
        await _saveString(_kGeminiModel, model);
    }
  }

  void setSTTMode(STTMode m) async {
    _sttMode = m;
    await _saveInt(_kSTTMode, m.index);
  }

  void setTTSMode(TTSMode m) async {
    _ttsMode = m;
    await _saveInt(_kTTSMode, m.index);
  }

  void setWakeWordEnabled(bool v) async {
    _wakeWordEnabled = v;
    await _saveBool(_kWakeWordEnabled, v);
  }

  void setUserName(String v) async {
    _userName = v.trim().isEmpty ? 'Efendim' : v.trim();
    await _saveString(_kUserName, _userName);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    notifyListeners();
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }
}
