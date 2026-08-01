import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/ai/llm_client.dart';
import '../services/ai/speech_service.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JARVISViewModel>();
    if (!vm.ready) {
      return const Center(
        child: CircularProgressIndicator(color: JARVISTheme.primary),
      );
    }
    final chat = vm.chat;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [JARVISTheme.background, Color(0xFF0E0E22)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(chat),
            Expanded(child: _buildMessages(chat)),
            _buildLiveTranscript(chat),
            _buildInputBar(chat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatViewModel chat) {
    final configured = chat.settings.isConfigured;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: configured ? JARVISTheme.primary : JARVISTheme.warning,
              boxShadow: [
                BoxShadow(
                  color: (configured ? JARVISTheme.primary : JARVISTheme.warning).withOpacity(0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('J.A.R.V.I.S.',
                  style: TextStyle(
                      color: JARVISTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      fontSize: 16)),
                Text(
                  configured
                      ? 'BAĞLI: ${chat.settings.provider.name.toUpperCase()} • ${chat.settings.activeModel}'
                      : 'AYARLARDAN API ANAHTARI GİRİN',
                style: const TextStyle(
                    color: JARVISTheme.textSecondary, fontSize: 9, letterSpacing: 1),
              ),
            ],
          ),
          const Spacer(),
          ValueListenableBuilder<SpeakingState>(
            valueListenable: chat.speech.state,
            builder: (context, state, _) {
              if (state != SpeakingState.speaking) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.stop_circle,
                    color: JARVISTheme.danger, size: 22),
                onPressed: chat.stopSpeaking,
                tooltip: 'Konuşmayı durdur',
              );
            },
          ),
          if (chat.wakeWordSupported) ...[
            ValueListenableBuilder<SpeakingState>(
              valueListenable: chat.speech.state,
              builder: (context, state, _) {
                final wakeActive = chat.wakeRunning;
                return IconButton(
                  icon: Icon(
                    wakeActive ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                    color:
                        wakeActive ? JARVISTheme.success : JARVISTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: wakeActive ? chat.stopWakeWord : chat.startWakeWord,
                  tooltip: 'Uyandırma: "Jarvis" deyin',
                );
              },
            ),
          ],
          IconButton(
            icon: Icon(
              chat.speakAfterReply ? Icons.volume_up : Icons.volume_off,
              color: chat.speakAfterReply ? JARVISTheme.primary : JARVISTheme.textSecondary,
              size: 20,
            ),
            onPressed: () => chat.speakAfterReply = !chat.speakAfterReply,
            tooltip: 'Sesli yanıt',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: JARVISTheme.textSecondary, size: 20),
            onPressed: chat.entries.isEmpty ? null : chat.clear,
            tooltip: 'Sohbeti temizle',
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ChatViewModel chat) {
    if (chat.entries.isEmpty) {
      return _buildEmptyState(chat);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: chat.entries.length,
      itemBuilder: (context, index) {
        final entry = chat.entries[index];
        final isUser = entry.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              color: isUser
                  ? JARVISTheme.secondary.withOpacity(0.25)
                  : JARVISTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 14),
              ),
              border: Border.all(
                  color: entry.isError
                      ? JARVISTheme.danger.withOpacity(0.5)
                      : JARVISTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: TextStyle(
                    color: entry.isError ? JARVISTheme.danger : JARVISTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (entry.tools.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.tools.map((t) => _toolChip(t)).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolChip(ToolInvocation tool) {
    final label = switch (tool.name) {
      'set_flashlight' => '🔦 El feneri',
      'set_brightness' => '☀️ Parlaklık',
      'get_battery' => '🔋 Pil',
      'take_photo' => '📷 Kamera',
      'set_timer' => '⏱ Zamanlayıcı',
      'schedule_reminder' => '🔔 Hatırlatıcı',
      'add_calendar_event' => '📅 Takvim',
      'search_contacts' => '👤 Rehber',
      'call_phone' => '📞 Arama',
      'send_sms' => '💬 Mesaj',
      'send_email' => '✉️ E-posta',
      'get_location' => '📍 Konum',
      'get_weather' => '🌤 Hava durumu',
      'copy_to_clipboard' => '📋 Pano',
      'open_url' => '🔗 Bağlantı',
      'get_time' => '🕐 Saat',
      'read_clipboard' => '📋 Pano oku',
      'send_whatsapp' => '💬 WhatsApp',
      'haptic_feedback' => '📳 Titreşim',
      'open_settings' => '⚙️ Ayarlar',
      _ => '🛠 ${tool.name}',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: JARVISTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: JARVISTheme.primary.withOpacity(0.25)),
      ),
      child: Text(label,
          style: const TextStyle(color: JARVISTheme.primary, fontSize: 10)),
    );
  }

  Widget _buildEmptyState(ChatViewModel chat) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JARVISTheme.primary.withOpacity(0.08),
              border: Border.all(color: JARVISTheme.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.mic_none, color: JARVISTheme.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Sizi dinliyorum ${chat.settings.userName}...',
              style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 16, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Mikrofona basın ya da yazın. "Pepper\'ı ara", "hava nasıl" gibi komutları yerine getiririm. '
              'Ayarlarda uyandırma kelimesini açarsanız "Jarvis..." deyip komut verebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLiveTranscript(ChatViewModel chat) {
    if (!chat.listening && chat.liveTranscript.value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: JARVISTheme.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: JARVISTheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: JARVISTheme.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chat.listening && chat.liveTranscript.value.isEmpty
                  ? 'Dinleniyor...'
                  : chat.liveTranscript.value,
              style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 12),
            ),
          ),
          if (chat.listening)
            GestureDetector(
              onTap: chat.cancelListening,
              child: const Icon(Icons.close, color: JARVISTheme.danger, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatViewModel chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: JARVISTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              style: const TextStyle(color: JARVISTheme.textPrimary),
              enabled: !chat.busy,
              decoration: InputDecoration(
                hintText: 'Komutunuzu yazın...',
                hintStyle: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 13),
                filled: true,
                fillColor: JARVISTheme.surfaceLight.withOpacity(0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (val) {
                if (val.isNotEmpty && !chat.busy) {
                  _input.clear();
                  chat.send(val);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          _buildMicButton(chat),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_input.text.isNotEmpty && !chat.busy) {
                final text = _input.text;
                _input.clear();
                chat.send(text);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: chat.busy
                    ? JARVISTheme.surfaceLight
                    : JARVISTheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                chat.busy ? Icons.hourglass_top : Icons.send,
                color: chat.busy ? JARVISTheme.textSecondary : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(ChatViewModel chat) {
    final active = chat.listening;
    return GestureDetector(
      onTap: () => chat.toggleListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? JARVISTheme.danger : JARVISTheme.primary,
          shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: JARVISTheme.danger.withOpacity(0.6), blurRadius: 14)]
              : [BoxShadow(color: JARVISTheme.primary.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Icon(
          active ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
