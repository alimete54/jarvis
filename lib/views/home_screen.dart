import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/settings_service.dart';
import '../viewmodels/jarvis_viewmodel.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JARVISViewModel>();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HUDPainter(),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(vm),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusGrid(vm),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, vm),
                      const SizedBox(height: 16),
                      _buildVoiceCard(context, vm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(JARVISViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [JARVISTheme.surface.withOpacity(0.9), JARVISTheme.surface.withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JARVISTheme.primary,
              boxShadow: [BoxShadow(color: JARVISTheme.primary.withOpacity(0.8), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('J.A.R.V.I.S.',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3, color: JARVISTheme.textPrimary)),
              Text('Just A Rather Very Intelligent System',
                  style: TextStyle(fontSize: 10, color: JARVISTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          _buildSystemStatus(vm),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(JARVISViewModel vm) {
    final configured = vm.settings.isConfigured;
    final color = configured ? JARVISTheme.success : JARVISTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(configured ? Icons.check_circle : Icons.warning_amber,
              color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            configured
                ? 'AI BAĞLI (${vm.settings.provider.name.toUpperCase()})'
                : 'AI ANAHTARI GEREK',
            style: TextStyle(color: color, fontSize: 10, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(JARVISViewModel vm) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatusCard(
          icon: Icons.smartphone,
          label: 'TELEFON AJANI',
          value: 'HAZIR',
          color: JARVISTheme.secondary,
          sub: 'El feneri • parlaklık • kamera',
        ),
        _StatusCard(
          icon: Icons.mic,
          label: 'SES',
          value: vm.settings.sttMode == STTMode.onDevice ? 'CİHAZ İÇİ' : 'BULUT',
          color: JARVISTheme.primary,
          sub: 'STT: ${_sttLabel(vm)} • TTS: ${_ttsLabel(vm)}',
        ),
        _StatusCard(
          icon: Icons.phone,
          label: 'İLETİŞİM',
          value: 'REHBER',
          color: JARVISTheme.primary,
          sub: 'Arama • SMS • E-posta (onaylı)',
        ),
        _StatusCard(
          icon: Icons.schedule,
          label: 'OTOMASYON',
          value: 'ZAMANLAYICI',
          color: JARVISTheme.hologram,
          sub: 'Hatırlatıcı • takvim etkinliği',
        ),
      ],
    );
  }

  String _sttLabel(JARVISViewModel vm) {
    return switch (vm.settings.sttMode) {
      STTMode.onDevice => 'cihaz',
      STTMode.whisper => 'whisper',
      STTMode.geminiAudio => 'gemini',
    };
  }

  String _ttsLabel(JARVISViewModel vm) {
    return switch (vm.settings.ttsMode) {
      TTSMode.system => 'sistem',
      TTSMode.openai => 'openai',
    };
  }

  Widget _buildQuickActions(BuildContext context, JARVISViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HIZLI İŞLEMLER',
            style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionChip(
              icon: Icons.mic,
              label: 'Jarvis ile Konuş',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ChatScreen())),
            ),
            _ActionChip(
              icon: Icons.flashlight_on,
              label: 'El Feneri',
              onTap: () => vm.executor.execute('set_flashlight', {'on': true}),
            ),
            _ActionChip(
              icon: Icons.camera_alt,
              label: 'Fotoğraf Analizi',
              onTap: () => vm.executor.execute('take_photo', {
                'question': 'Ne görüyorsun? Detaylı anlat.',
              }),
            ),
            _ActionChip(
              icon: Icons.cloud,
              label: 'Hava Durumu',
              onTap: () => vm.executor.execute('get_weather', const {}),
            ),
            _ActionChip(
              icon: Icons.alarm,
              label: '10 dk Zamanlayıcı',
              onTap: () => vm.executor
                  .execute('set_timer', {'minutes': 10, 'label': 'Zamanlayıcı (10 dk)'}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceCard(BuildContext context, JARVISViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [JARVISTheme.surface, JARVISTheme.secondary.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JARVISTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JARVISTheme.primary.withOpacity(0.12),
              border: Border.all(color: JARVISTheme.primary.withOpacity(0.4)),
            ),
            child: const Icon(Icons.smart_toy, color: JARVISTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sesli asistana geç',
                    style: TextStyle(color: JARVISTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  vm.settings.isConfigured
                      ? 'Mikrofona basın, Jarvis sizi dinlesin.'
                      : 'Önce Ayarlar sekmesinden API anahtarınızı girin.',
                  style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: JARVISTheme.primary),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String sub;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JARVISTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 9, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(sub, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: JARVISTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: JARVISTheme.primary.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: JARVISTheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 12, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HUDPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = JARVISTheme.primary.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
