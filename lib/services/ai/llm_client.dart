import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:jarvis/services/settings_service.dart';

import 'tools.dart';
import 'tool_executor.dart';

class ChatMessage {
  final String role;
  final String? content;
  final String? toolCallId;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;

  const ChatMessage.user(String content)
      : role = 'user',
        content = content,
        toolCallId = null,
        toolName = null,
        toolArgs = null;

  const ChatMessage.assistant(String content)
      : role = 'assistant',
        content = content,
        toolCallId = null,
        toolName = null,
        toolArgs = null;

  const ChatMessage.toolResult({required this.toolCallId, required String content})
      : role = 'tool',
        content = content,
        toolName = null,
        toolArgs = null;

  const ChatMessage.assistantToolCall({
    required this.toolName,
    required this.toolArgs,
    required this.toolCallId,
  })  : role = 'assistant',
        content = null;
}

class ToolInvocation {
  final String name;
  final Map<String, dynamic> args;

  const ToolInvocation(this.name, this.args);
}

class LLMException implements Exception {
  final String message;
  const LLMException(this.message);

  @override
  String toString() => message;
}

class LLMResult {
  final String text;
  final List<ToolInvocation> toolLog;

  const LLMResult(this.text, this.toolLog);
}

class LLMClient {
  final SettingsService settings;
  final ToolExecutor executor;

  LLMClient({required this.settings, required this.executor}) {
    executor.visionHandler = analyzeImage;
  }

  String get _systemPrompt {
    final now = DateTime.now();
    return '''
Sen JARVIS'sin — Tony Stark'ın yapay zekâ asistanısın. Kullanıcı ${settings.userName}.
Kullanıcı Türkçe konuşuyorsa Türkçe, kullandığı dile göre yanıt ver. Kısa, doğal ve Stark'ın asistanı
gibi yardımsever ol. Tarih: ${now.day}.${now.month}.${now.year}, saat: ${now.hour}:${now.minute.toString().padLeft(2, '0')}.

Elinin altındaki araçlar: el feneri, ekran parlaklığı, pil bilgisi, kamera ile fotoğraf çekip analiz,
zamanlayıcı, hatırlatıcı (tarih/saat ver), takvime etkinlik ekleme, rehberde kişi arama, telefon arama,
SMS yazma, e-posta taslağı, konum, hava durumu, pano (kopyala), URL açma.

Kurallar:
- "X'i ara" → önce search_contacts ile kişiyi bul, numarasını call_phone ile çağır.
- "X'e mesaj at" → search_contacts ile numara bul, send_sms ile mesajı yaz.
- Tarih içeren "hatırlat" → schedule_reminder (ISO 8601, yerel saat).
- "dakika sonra" → set_timer.
- "hava nasıl" → get_weather (önce get_location çağırabilirsin).
- "ne görüyorsun" → take_photo.
- Bir araç hata dönerse, kullanıcıya anlaşılır Türkçe anlat.
- Arama ve mesaj işlemlerinde kullanıcı onayı telefonda gösterilir; bunu belirt.
''';
  }

  /// Tek tur: mesaj geçmişini gönder, araç çağrılarını yürüt, sonuca ulaş.
  Future<LLMResult> chat(
    List<ChatMessage> history, {
    void Function(ToolInvocation tool)? onToolCall,
  }) async {
    if (!settings.isConfigured) {
      throw const LLMException(
        'Henüz bir API anahtarı tanımlanmadı. Ayarlar ekranından OpenAI, Anthropic veya Gemini anahtarını girin.',
      );
    }
    final messages = <ChatMessage>[
      ChatMessage.assistant(_systemPrompt),
      ...history,
    ];

    final toolLog = <ToolInvocation>[];

    for (var round = 0; round < 6; round++) {
      final response = await _callProvider(messages);
      messages.addAll(response.toolCalls.isEmpty
          ? <ChatMessage>[]
          : response.toolCalls.map((c) => ChatMessage.assistantToolCall(
                toolName: c.name,
                toolArgs: c.args,
                toolCallId: c.id,
              )));

      if (response.toolCalls.isEmpty) {
        return LLMResult(response.text, toolLog);
      }

      for (final call in response.toolCalls) {
        final invocation = ToolInvocation(call.name, call.args);
        toolLog.add(invocation);
        onToolCall?.call(invocation);
        final result = await executor.execute(call.name, call.args);
        messages.add(ChatMessage.toolResult(
          toolCallId: call.id,
          content: result.message,
        ));
      }
    }
    throw const LLMException('Çok fazla araç çağrısı yapıldı, işlem durduruldu.');
  }

  Future<String> analyzeImage(String imagePath, String question) async {
    if (!settings.isConfigured) {
      throw const LLMException('Görüntü analizi için AI anahtarı gerekli.');
    }
    final bytes = await File(imagePath).readAsBytes();
    final base64 = base64Encode(bytes);
    final mime = imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    switch (settings.provider) {
      case AIProvider.openai:
        final response = await _postJson(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          {
            'Authorization': 'Bearer ${settings.openAIKey}',
          },
          {
            'model': settings.openAIModel,
            'max_tokens': 512,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': question},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:$mime;base64,$base64'},
                  },
                ],
              },
            ],
          },
        );
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final text = ((body['choices'] as List).first as Map<String, dynamic>)['message']
            ['content'] as String?;
        if (text == null) throw const LLMException('Görüntü analizi yanıtı alınamadı.');
        return text;

      case AIProvider.anthropic:
        final response = await _postJson(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          {
            'x-api-key': settings.anthropicKey,
            'anthropic-version': '2023-06-01',
          },
          {
            'model': settings.anthropicModel,
            'max_tokens': 512,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': question},
                  {
                    'type': 'image',
                    'source': {'type': 'base64', 'media_type': mime, 'data': base64},
                  },
                ],
              },
            ],
          },
        );
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final blocks = body['content'] as List;
        final text = blocks
            .map((b) => (b as Map<String, dynamic>)['text'] as String?)
            .whereType<String>()
            .join();
        if (text.isEmpty) throw const LLMException('Görüntü analizi yanıtı alınamadı.');
        return text;

      case AIProvider.gemini:
        final response = await _postJson(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/${settings.geminiModel}:generateContent?key=${settings.geminiKey}',
          ),
          {},
          {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': question},
                  {'inlineData': {'mimeType': mime, 'data': base64}},
                ],
              },
            ],
          },
        );
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _geminiText(body);
        if (text.isEmpty) throw const LLMException('Görüntü analizi yanıtı alınamadı.');
        return text;
    }
  }

  Future<_ProviderResponse> _callProvider(List<ChatMessage> messages) async {
    switch (settings.provider) {
      case AIProvider.openai:
        return _callOpenAI(messages);
      case AIProvider.anthropic:
        return _callAnthropic(messages);
      case AIProvider.gemini:
        return _callGemini(messages);
    }
  }

  // ─────────────────────────── OpenAI ───────────────────────────

  Future<_ProviderResponse> _callOpenAI(List<ChatMessage> messages) async {
    final response = await _postJson(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      {'Authorization': 'Bearer ${settings.openAIKey}'},
      {
        'model': settings.openAIModel,
        'messages': messages.map(_openAIMessage).toList(),
        'tools': toolDefinitions
            .map((t) => {
                  'type': 'function',
                  'function': {
                    'name': t['name'],
                    'description': t['description'],
                    'parameters': t['parameters'],
                  },
                })
            .toList(),
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final message = ((body['choices'] as List).first as Map<String, dynamic>)['message']
        as Map<String, dynamic>;
    final text = message['content'] as String? ?? '';
    final calls = <_ToolCall>[];
    final rawCalls = message['tool_calls'] as List? ?? [];
    for (final raw in rawCalls) {
      final fn = (raw as Map<String, dynamic>)['function'] as Map<String, dynamic>;
      calls.add(_ToolCall(
        id: raw['id'] as String,
        name: fn['name'] as String,
        args: (jsonDecode(fn['arguments'] as String) as Map<String, dynamic>?) ?? const {},
      ));
    }
    return _ProviderResponse(text, calls);
  }

  Map<String, dynamic> _openAIMessage(ChatMessage m) {
    switch (m.role) {
      case 'tool':
        return {
          'role': 'tool',
          'tool_call_id': m.toolCallId,
          'content': m.content,
        };
      case 'assistant':
        if (m.toolName != null) {
          return {
            'role': 'assistant',
            'content': null,
            'tool_calls': [
              {
                'id': m.toolCallId,
                'type': 'function',
                'function': {'name': m.toolName, 'arguments': jsonEncode(m.toolArgs ?? const {})},
              },
            ],
          };
        }
        return {'role': 'assistant', 'content': m.content};
      default:
        return {'role': 'user', 'content': m.content};
    }
  }

  // ────────────────────────── Anthropic ──────────────────────────

  Future<_ProviderResponse> _callAnthropic(List<ChatMessage> messages) async {
    final system = messages.where((m) => m.role == 'system').map((m) => m.content!).join('\n');
    final history = messages.where((m) => m.role != 'system').toList();

    final response = await _postJson(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      {'x-api-key': settings.anthropicKey, 'anthropic-version': '2023-06-01'},
      {
        'model': settings.anthropicModel,
        'max_tokens': 1024,
        if (system.isNotEmpty) 'system': system,
        'messages': history.map(_anthropicMessage).toList(),
        'tools': toolDefinitions
            .map((t) => {
                  'name': t['name'],
                  'description': t['description'],
                  'input_schema': t['parameters'],
                })
            .toList(),
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final blocks = (body['content'] as List? ?? [])
        .map((b) => b as Map<String, dynamic>)
        .toList();
    final text = blocks
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    final calls = blocks
        .where((b) => b['type'] == 'tool_use')
        .map((b) => _ToolCall(
              id: b['id'] as String,
              name: b['name'] as String,
              args: (b['input'] as Map<String, dynamic>?) ?? const {},
            ))
        .toList();
    return _ProviderResponse(text, calls);
  }

  Map<String, dynamic> _anthropicMessage(ChatMessage m) {
    switch (m.role) {
      case 'tool':
        return {
          'role': 'user',
          'content': [
            {'type': 'tool_result', 'tool_use_id': m.toolCallId, 'content': m.content},
          ],
        };
      case 'assistant':
        if (m.toolName != null) {
          return {
            'role': 'assistant',
            'content': [
              {
                'type': 'tool_use',
                'id': m.toolCallId,
                'name': m.toolName,
                'input': m.toolArgs ?? const {},
              },
            ],
          };
        }
        return {'role': 'assistant', 'content': m.content};
      default:
        return {'role': 'user', 'content': m.content};
    }
  }

  // ─────────────────────────── Gemini ───────────────────────────

  Future<_ProviderResponse> _callGemini(List<ChatMessage> messages) async {
    final system = messages.where((m) => m.role == 'system').map((m) => m.content!).join('\n');
    final history = messages.where((m) => m.role != 'system').toList();

    final response = await _postJson(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${settings.geminiModel}:generateContent?key=${settings.geminiKey}',
      ),
      {},
      {
        if (system.isNotEmpty)
          'system_instruction': {
            'parts': [
              {'text': system},
            ],
          },
        'contents': history.map(_geminiContent).toList(),
        'tools': [
          {
            'functionDeclarations': toolDefinitions
                .map((t) => {
                      'name': t['name'],
                      'description': t['description'],
                      'parameters': t['parameters'],
                    })
                .toList(),
          },
        ],
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final parts = _geminiParts(body);
    final text = parts
        .where((p) => p.containsKey('text'))
        .map((p) => p['text'] as String)
        .join();
    final calls = parts
        .where((p) => p.containsKey('functionCall'))
        .map((p) {
      final fc = p['functionCall'] as Map<String, dynamic>;
      return _ToolCall(
        id: 'gem-${DateTime.now().microsecondsSinceEpoch}',
        name: fc['name'] as String,
        args: (fc['args'] as Map<String, dynamic>?) ?? const {},
      );
    }).toList();
    return _ProviderResponse(text, calls);
  }

  Map<String, dynamic> _geminiContent(ChatMessage m) {
    switch (m.role) {
      case 'tool':
        return {
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'name': 'tool_result',
                'response': {'result': m.content},
              },
            },
          ],
        };
      case 'assistant':
        if (m.toolName != null) {
          return {
            'role': 'model',
            'parts': [
              {'functionCall': {'name': m.toolName, 'args': m.toolArgs ?? const {}}},
            ],
          };
        }
        return {
          'role': 'model',
          'parts': [
            {'text': m.content},
          ],
        };
      default:
        return {
          'role': 'user',
          'parts': [
            {'text': m.content},
          ],
        };
    }
  }

  List<Map<String, dynamic>> _geminiParts(Map<String, dynamic> body) {
    final candidates = body['candidates'] as List? ?? [];
    if (candidates.isEmpty) {
      final error = body['error'] as Map<String, dynamic>?;
      final msg = error?['message'] as String? ?? 'Yanıt alınamadı';
      throw LLMException('Gemini hatası: $msg');
    }
    final content = (candidates.first as Map<String, dynamic>)['content']
        as Map<String, dynamic>?;
    final parts = (content?['parts'] as List? ?? [])
        .map((p) => (p as Map<String, dynamic>?) ?? const {})
        .toList();
    if (parts.isEmpty && content != null) {
      throw const LLMException('Gemini yanıt boş (bloklanmış olabilir).');
    }
    return parts;
  }

  String _geminiText(Map<String, dynamic> body) {
    return _geminiParts(body)
        .where((p) => p.containsKey('text'))
        .map((p) => p['text'] as String)
        .join();
  }

  // ─────────────────────────── Yardımcılar ───────────────────────────

  Future<http.Response> _postJson(Uri uri, Map<String, String> headers, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', ...headers},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } on SocketException {
      throw const LLMException('İnternet bağlantısı yok.');
    } on TimeoutException {
      throw const LLMException('AI yanıtı zaman aşımına uğradı.');
    }
    if (response.statusCode >= 400) {
      final message = _extractError(response.body);
      throw LLMException('API hatası (${response.statusCode}): $message');
    }
    return response;
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error']?['message'] as String? ??
          json['message'] as String? ??
          body;
    } catch (_) {
      return body;
    }
  }
}

class _ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> args;

  const _ToolCall({required this.id, required this.name, required this.args});
}

class _ProviderResponse {
  final String text;
  final List<_ToolCall> toolCalls;

  const _ProviderResponse(this.text, this.toolCalls);
}
