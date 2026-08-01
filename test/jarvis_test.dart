import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jarvis/services/ai/llm_client.dart';
import 'package:jarvis/services/ai/tools.dart';
import 'package:jarvis/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Tool definitions', () {
    test('all tools have name, description and parameters', () {
      for (final tool in toolDefinitions) {
        expect(tool['name'], isNotEmpty);
        expect(tool['description'], isNotEmpty);
        expect(tool['parameters'], isNotNull);
      }
    });

    test('every tool in definitions is unique', () {
      final names = toolDefinitions.map((t) => t['name']).toSet();
      expect(names.length, toolDefinitions.length);
    });
  });

  group('ChatMessage', () {
    test('user message role', () {
      const msg = ChatMessage.user('merhaba');
      expect(msg.role, 'user');
      expect(msg.content, 'merhaba');
    });

    test('assistant tool call message', () {
      const msg = ChatMessage.assistantToolCall(
        toolName: 'set_flashlight',
        toolArgs: {'on': true},
        toolCallId: 'call_1',
      );
      expect(msg.role, 'assistant');
      expect(msg.toolName, 'set_flashlight');
      expect(msg.toolArgs, {'on': true});
    });

    test('tool result message', () {
      const msg = ChatMessage.toolResult(
        toolCallId: 'call_1',
        content: 'El feneri açıldı.',
      );
      expect(msg.role, 'tool');
      expect(msg.toolCallId, 'call_1');
    });
  });

  group('SettingsService', () {
    test('defaults are sensible', () async {
      final settings = SettingsService();
      await settings.load();
      expect(settings.provider, AIProvider.openai);
      expect(settings.sttMode, STTMode.onDevice);
      expect(settings.ttsMode, TTSMode.system);
      expect(settings.isConfigured, isFalse);
      expect(settings.userName, isNotEmpty);
    });

    test('provider change updates active key source', () {
      final settings = SettingsService();
      expect(settings.activeModel, isNotEmpty);
    });
  });
}
