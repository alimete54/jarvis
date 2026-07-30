import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/services/ai_engine.dart';
import 'package:jarvis/services/home_kit_service.dart';
import 'package:jarvis/services/security_service.dart';
import 'package:jarvis/services/communication_service.dart';
import 'package:jarvis/services/phone_agent_service.dart';
import 'package:jarvis/models/device.dart';

void main() {
  group('AI Engine Tests', () {
    test('should greet user', () {
      final engine = AIEngine();
      final response = engine.processInput('merhaba');
      expect(response, contains('Efendim'));
    });

    test('should identify urgent tone', () {
      final engine = AIEngine();
      final tone = engine.analyzeTone('hemen gel acil');
      expect(tone, equals('URGENT'));
    });
  });

  group('HomeKit Service Tests', () {
    test('should initialize with devices', () {
      final service = HomeKitService();
      expect(service.devices.length, greaterThan(0));
    });

    test('should toggle device', () {
      final service = HomeKitService();
      final initial = service.devices.first.status;
      service.toggleDevice('light_1');
      expect(service.devices.first.status, isNot(initial));
    });
  });

  group('Security Service Tests', () {
    test('should detect intrusions', () {
      final service = SecurityService();
      service.detectIntrusion();
      expect(service.intrusionAttempts, equals(1));
    });
  });

  group('Communication Service Tests', () {
    test('should add and retrieve messages', () {
      final service = CommunicationService();
      service.addMessage('Test', 'Hello', MessageType.sms);
      expect(service.messages.length, equals(1));
    });
  });

  group('Phone Agent Service Tests', () {
    test('should initialize with contacts', () {
      final service = PhoneAgentService();
      expect(service.contacts.length, greaterThan(0));
    });

    test('should send SMS', () {
      final service = PhoneAgentService();
      final result = service.sendSms('Pepper', 'Test mesajı');
      expect(result, contains('Pepper'));
    });

    test('should call contact', () {
      final service = PhoneAgentService();
      final result = service.callContact('Rhodey');
      expect(result, contains('Rhodey'));
    });

    test('should toggle Wi-Fi', () {
      final service = PhoneAgentService();
      final initial = service.isWifiOn;
      service.toggleWifi();
      expect(service.isWifiOn, isNot(initial));
    });

    test('should toggle Bluetooth', () {
      final service = PhoneAgentService();
      final initial = service.isBluetoothOn;
      service.toggleBluetooth();
      expect(service.isBluetoothOn, isNot(initial));
    });

    test('should set brightness', () {
      final service = PhoneAgentService();
      service.setBrightness(0.5);
      expect(service.screenBrightness, equals(0.5));
    });

    test('should execute command', () {
      final service = PhoneAgentService();
      final result = service.executeCommand('pil');
      expect(result, contains('%'));
    });

    test('should find contact', () {
      final service = PhoneAgentService();
      final contact = service.findContact('Fury');
      expect(contact, isNotNull);
      expect(contact!.name, contains('Fury'));
    });

    test('should toggle DND', () {
      final service = PhoneAgentService();
      final initial = service.isDndOn;
      service.toggleDnd();
      expect(service.isDndOn, isNot(initial));
    });

    test('should copy to clipboard', () {
      final service = PhoneAgentService();
      service.copyToClipboard('Test');
      expect(service.lastClipboard, equals('Test'));
    });

    test('should execute smart commands', () {
      final service = PhoneAgentService();
      final result = service.executeCommand('ara Pepper Potts');
      expect(result, contains('Pepper'));
    });
  });
}
