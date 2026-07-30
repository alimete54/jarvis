import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/home_kit_service.dart';
import '../services/security_service.dart';
import '../services/communication_service.dart';
import '../services/phone_agent_service.dart';
import '../services/ai_engine.dart';

class JARVISViewModel extends ChangeNotifier {
  final VoiceService voiceService = VoiceService();
  final HomeKitService homeKitService = HomeKitService();
  final SecurityService securityService = SecurityService();
  final CommunicationService communicationService = CommunicationService();
  final PhoneAgentService phoneAgentService = PhoneAgentService();
  final AIEngine aiEngine = AIEngine();

  String _lastResponse = '';
  String _inputText = '';
  bool _isProcessing = false;
  int _currentScreenIndex = 0;

  String get lastResponse => _lastResponse;
  String get inputText => _inputText;
  bool get isProcessing => _isProcessing;
  int get currentScreenIndex => _currentScreenIndex;

  set inputText(String value) {
    _inputText = value;
    notifyListeners();
  }

  set currentScreenIndex(int index) {
    _currentScreenIndex = index;
    notifyListeners();
  }

  void sendCommand(String command) {
    if (command.isEmpty) return;
    _isProcessing = true;
    notifyListeners();

    final tone = aiEngine.analyzeTone(command);
    final response = aiEngine.processInput(command);
    _lastResponse = response;
    _processCommandContext(command);

    _isProcessing = false;
    notifyListeners();
  }

  void _processCommandContext(String command) {
    final lower = command.toLowerCase();

    if (lower.contains('ışık') || lower.contains('light')) {
      if (lower.contains('aç')) {
        homeKitService.toggleDevice('light_1');
        _lastResponse = 'Işıklar açıldı Efendim.';
      } else if (lower.contains('kapa')) {
        homeKitService.toggleDevice('light_1');
        _lastResponse = 'Işıklar kapatıldı Efendim.';
      }
      return;
    }

    final agentResult = phoneAgentService.executeCommand(command);
    if (!agentResult.startsWith('Anlaşılamadı')) {
      _lastResponse = agentResult;
      return;
    }
  }

  void processVoiceCommand(String text) {
    _inputText = text;
    sendCommand(text);
  }

  void scanNetwork() {
    securityService.scanNetwork();
    _lastResponse = 'Ağ taraması tamamlandı. Durum: ${securityService.securityStatus}';
    notifyListeners();
  }

  String executeAgentCommand(String command) {
    final result = phoneAgentService.executeCommand(command);
    _lastResponse = result;
    notifyListeners();
    return result;
  }
}
