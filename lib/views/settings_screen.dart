import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/settings_service.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _openAIKey;
  late final TextEditingController _anthropicKey;
  late final TextEditingController _geminiKey;
  late final TextEditingController _openAIModel;
  late final TextEditingController _anthropicModel;
  late final TextEditingController _geminiModel;
  late final TextEditingController _userName;
  bool _showKeys = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<JARVISViewModel>().settings;
    _openAIKey = TextEditingController(text: s.openAIKey);
    _anthropicKey = TextEditingController(text: s.anthropicKey);
    _geminiKey = TextEditingController(text: s.geminiKey);
    _openAIModel = TextEditingController(text: s.openAIModel);
    _anthropicModel = TextEditingController(text: s.anthropicModel);
    _geminiModel = TextEditingController(text: s.geminiModel);
    _userName = TextEditingController(text: s.userName);
  }

  @override
  void dispose() {
    _openAIKey.dispose();
    _anthropicKey.dispose();
    _geminiKey.dispose();
    _openAIModel.dispose();
    _anthropicModel.dispose();
    _geminiModel.dispose();
    _userName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<JARVISViewModel>().settings;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [JARVISTheme.background, JARVISTheme.surface.withOpacity(0.5)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('YAPAY ZEKÂ SAĞLAYICISI'),
            const SizedBox(height: 10),
            _providerCard(s),
            const SizedBox(height: 24),
            _sectionTitle('API ANAHTARLARI'),
            const SizedBox(height: 8),
            _apiKeyField(s, 'OpenAI', 'sk-...', Icons.circle,
                JARVISTheme.primary, _openAIKey, s.openAIKey, (v) => s.setOpenAIKey(v)),
            _apiKeyField(s, 'Anthropic', 'sk-ant-...', Icons.circle,
                JARVISTheme.accent, _anthropicKey, s.anthropicKey, (v) => s.setAnthropicKey(v)),
            _apiKeyField(s, 'Google Gemini', 'AIza...', Icons.circle,
                JARVISTheme.success, _geminiKey, s.geminiKey, (v) => s.setGeminiKey(v)),
            const SizedBox(height: 16),
            _modelField(s, 'OpenAI modeli', _openAIModel, (v) => s.setModel(AIProvider.openai, v)),
            _modelField(s, 'Anthropic modeli', _anthropicModel, (v) => s.setModel(AIProvider.anthropic, v)),
            _modelField(s, 'Gemini modeli', _geminiModel, (v) => s.setModel(AIProvider.gemini, v)),
            const SizedBox(height: 24),
            _sectionTitle('SES AYARLARI'),
            const SizedBox(height: 8),
            _dropdown<String>(
              label: 'Konuşma tanıma (STT)',
              icon: Icons.hearing,
              value: s.sttMode.name,
              items: const {
                'onDevice': 'Cihaz üzerinde (ücretsiz, internet gerektirmez)',
                'whisper': 'OpenAI Whisper (daha doğru, OpenAI anahtarı gerekir)',
                'geminiAudio': 'Gemini ses (Gemini anahtarı gerekir)',
              },
              onChanged: (v) => s.setSTTMode(STTMode.values.byName(v!)),
            ),
            const SizedBox(height: 8),
            _dropdown<String>(
              label: 'Sesli yanıt (TTS)',
              icon: Icons.record_voice_over,
              value: s.ttsMode.name,
              items: const {
                'system': 'iOS/Android sistem sesi (ücretsiz)',
                'openai': 'OpenAI TTS — Jarvis sesi (OpenAI anahtarı gerekir)',
              },
              onChanged: (v) => s.setTTSMode(TTSMode.values.byName(v!)),
            ),
            const SizedBox(height: 8),
            _wakeWordToggle(s),
            const SizedBox(height: 24),
            _sectionTitle('KİŞİSELLEŞTİRME'),
            const SizedBox(height: 8),
            _modelField(s, 'Jarvis size ne diyor?', _userName, (v) => s.setUserName(v)),
            const SizedBox(height: 24),
            _sectionTitle('iOS KISITLARI (BİLİNEN)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: JARVISTheme.warning.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JARVISTheme.warning.withOpacity(0.2)),
              ),
              child: const Text(
                'Apple, üçüncü parti uygulamaların Wi-Fi/Bluetooth\'u kapatmasını, sistem ses seviyesini değiştirmesini, SMS\'i arka planda göndermesini ve Rahatsız Etmeyin modunu açmasını YASAKLAR. '
                'Jarvis bunları telefonun kendi onay ekranlarıyla yapar (arama/mesaj taslağı gibi). HomeKit ve Siri Kısayolları native geliştirme gerektirir — ileriki sürümde. '
                'Anahtarlar cihazda saklanır (SharedPreferences).',
                style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _wakeWordToggle(SettingsService s) {
    final supported = s.sttMode == STTMode.onDevice;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: JARVISTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JARVISTheme.surfaceLight),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: s.wakeWordEnabled,
        onChanged: supported ? s.setWakeWordEnabled : null,
        activeTrackColor: JARVISTheme.success,
        title: const Text('Uyandırma kelimesi',
            style: TextStyle(color: JARVISTheme.textPrimary, fontSize: 13)),
        subtitle: Text(
          supported
              ? '"Jarvis" deyince uygulamada otomatik dinlemeye geçer (cihaz üzeri STT)'
              : 'Cihaz üzeri STT gerektirir (yukarıdan seçin)',
          style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 10),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: JARVISTheme.primary,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600));
  }

  Widget _providerCard(SettingsService s) {
    final options = {
      AIProvider.openai: ('OpenAI', 'GPT — en yaygın, Whisper + TTS dahil', Icons.auto_awesome, JARVISTheme.primary),
      AIProvider.anthropic: ('Anthropic', 'Claude — güçlü araç kullanımı', Icons.science, JARVISTheme.accent),
      AIProvider.gemini: ('Google Gemini', 'Hızlı ve ses girişi destekli', Icons.rocket_launch, JARVISTheme.success),
    };
    return Column(
      children: options.entries.map((entry) {
        final (name, desc, icon, color) = entry.value;
        final selected = s.provider == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => s.setProvider(entry.key),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.1) : JARVISTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? color : JARVISTheme.surfaceLight,
                      width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  color: JARVISTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(desc,
                              style: const TextStyle(
                                  color: JARVISTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected ? color : JARVISTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _apiKeyField(
    SettingsService s,
    String label,
    String hint,
    IconData icon,
    Color color,
    TextEditingController controller,
    String stored,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: JARVISTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JARVISTheme.surfaceLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: !_showKeys,
                style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: '$label API anahtarı',
                  labelStyle: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11),
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: JARVISTheme.textSecondary.withOpacity(0.4),
                      fontSize: 12),
                  border: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
            if (stored.isNotEmpty)
              const Icon(Icons.check_circle, color: JARVISTheme.success, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _modelField(
    SettingsService s,
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11),
          filled: true,
          fillColor: JARVISTheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: JARVISTheme.surfaceLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: JARVISTheme.surfaceLight),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: JARVISTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JARVISTheme.surfaceLight),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: JARVISTheme.surfaceLight,
        icon: const Icon(Icons.arrow_drop_down, color: JARVISTheme.textSecondary),
        style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11),
          icon: Icon(icon, color: JARVISTheme.primary, size: 18),
          border: InputBorder.none,
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
