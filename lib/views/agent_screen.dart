import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  bool _torchOn = false;
  double _brightness = 0.8;

  Future<void> _run(String tool, Map<String, dynamic> args, String label) async {
    final vm = context.read<JARVISViewModel>();
    try {
      final result = await vm.executor.execute(tool, args);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message, style: const TextStyle(fontSize: 12)),
        backgroundColor: result.ok ? JARVISTheme.surfaceLight : JARVISTheme.danger,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
      if (tool == 'set_flashlight') {
        setState(() => _torchOn = args['on'] as bool);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: $e', style: const TextStyle(fontSize: 12)),
          backgroundColor: JARVISTheme.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JARVISViewModel>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [JARVISTheme.background, JARVISTheme.surface.withOpacity(0.5)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _sectionTitle('CİHAZ KONTROLLERİ'),
              const SizedBox(height: 10),
              _buildDeviceControls(),
              const SizedBox(height: 20),
              _sectionTitle('KAMERA & GÖRÜŞ'),
              const SizedBox(height: 10),
              _buildVision(vm),
              const SizedBox(height: 20),
              _sectionTitle('ZAMANLAYICI'),
              const SizedBox(height: 10),
              _buildTimers(),
              const SizedBox(height: 20),
              _sectionTitle('BİLGİ SERVİSLERİ'),
              const SizedBox(height: 10),
              _buildInfo(vm),
              const SizedBox(height: 20),
              _sectionTitle('YAPABİLECEKLERİM'),
              const SizedBox(height: 10),
              _buildCapabilities(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JARVISTheme.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.smartphone, color: JARVISTheme.secondary, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TELEFON AJANI',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: JARVISTheme.textPrimary)),
            Text('Kontrol • Yönetim • Otomasyon',
                style: TextStyle(fontSize: 11, color: JARVISTheme.textSecondary, letterSpacing: 1)),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2));
  }

  Widget _buildDeviceControls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionCard(
          icon: Icons.flashlight_on,
          label: _torchOn ? 'FENER: AÇIK' : 'FENER: KAPALI',
          color: _torchOn ? JARVISTheme.warning : JARVISTheme.textSecondary,
          onTap: () => _run('set_flashlight', {'on': !_torchOn}, 'el feneri'),
        ),
        _ActionCard(
          icon: Icons.brightness_6,
          label: 'PARLAKLIK',
          color: JARVISTheme.warning,
          onTap: () => _showBrightnessSheet(),
        ),
        _ActionCard(
          icon: Icons.battery_std,
          label: 'PİL DURUMU',
          color: JARVISTheme.success,
          onTap: () => _run('get_battery', const {}, 'pil'),
        ),
      ],
    );
  }

  Widget _buildVision(JARVISViewModel vm) {
    return _ActionCard(
      icon: Icons.camera_alt,
      label: vm.settings.isConfigured ? 'FOTOĞRAF ÇEK & ANALİZ ET' : 'FOTOĞRAF ÇEK (AI anahtarı gerekli)',
      color: vm.settings.isConfigured ? JARVISTheme.hologram : JARVISTheme.textSecondary,
      onTap: () => _run('take_photo', {'question': 'Ne görüyorsun? Detaylı anlat.'}, 'kamera'),
    );
  }

  Widget _buildTimers() {
    return Row(
      children: [
        for (final minutes in [5, 10, 20])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ActionCard(
              icon: Icons.timer,
              label: '$minutes DK',
              color: JARVISTheme.primary,
              onTap: () => _run('set_timer', {'minutes': minutes, 'label': 'Zamanlayıcı ($minutes dk)'}, 'zamanlayıcı'),
            ),
          ),
        _ActionCard(
          icon: Icons.notifications_active,
          label: 'HATIRLATICI',
          color: JARVISTheme.secondary,
          onTap: () => _showReminderSheet(),
        ),
      ],
    );
  }

  Widget _buildInfo(JARVISViewModel vm) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionCard(
          icon: Icons.location_on,
          label: 'KONUM',
          color: JARVISTheme.primary,
          onTap: () => _run('get_location', const {}, 'konum'),
        ),
        _ActionCard(
          icon: Icons.cloud,
          label: 'HAVA DURUMU',
          color: JARVISTheme.accent,
          onTap: () => _run('get_weather', const {}, 'hava'),
        ),
        _ActionCard(
          icon: Icons.contacts,
          label: 'REHBERDE ARA',
          color: JARVISTheme.hologram,
          onTap: () => _showContactSearch(vm),
        ),
      ],
    );
  }

  Widget _buildCapabilities() {
    const capabilities = [
      (Icons.lightbulb, 'El feneri aç/kapat'),
      (Icons.brightness_6, 'Ekran parlaklığı'),
      (Icons.phone, 'Arama başlatma (onaylı)'),
      (Icons.sms, 'SMS taslağı'),
      (Icons.mail, 'E-posta taslağı'),
      (Icons.calendar_month, 'Takvime etkinlik ekleme'),
      (Icons.alarm, 'Zamanlayıcı & hatırlatıcı'),
      (Icons.photo_camera, 'Kamera ile görüntü analizi'),
      (Icons.location_on, 'Konum tespiti'),
      (Icons.cloud, 'Hava durumu'),
      (Icons.content_paste, 'Panoya kopyalama'),
      (Icons.bolt, 'URL/derin link açma'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: capabilities
          .map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: JARVISTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: JARVISTheme.surfaceLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.$1, color: JARVISTheme.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(c.$2,
                        style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _showBrightnessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: JARVISTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PARLAKLIK KONTROLÜ',
                  style: TextStyle(
                      color: JARVISTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.brightness_low, color: JARVISTheme.textSecondary),
                  Expanded(
                    child: Slider(
                      value: _brightness,
                      activeColor: JARVISTheme.warning,
                      inactiveColor: JARVISTheme.surfaceLight,
                      onChanged: (val) {
                        setSheetState(() => _brightness = val);
                        _run('set_brightness', {'level': val}, 'parlaklık');
                      },
                    ),
                  ),
                  const Icon(Icons.brightness_high, color: JARVISTheme.textSecondary),
                ],
              ),
              Text('%${(_brightness * 100).round()}',
                  style: const TextStyle(
                      color: JARVISTheme.warning, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: JARVISTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HATIRLATICI',
                style: TextStyle(
                    color: JARVISTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: JARVISTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Ne hatırlatayım?',
                labelStyle: TextStyle(color: JARVISTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Dakika (1-120)',
                style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: JARVISTheme.secondary,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _run('schedule_reminder', {
                  'when': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
                  'text': controller.text,
                }, 'hatırlatıcı');
              },
              child: const Text('5 DAKİKA SONRA HATIRLAT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSearch(JARVISViewModel vm) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: JARVISTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REHBERDE ARA',
                style: TextStyle(
                    color: JARVISTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: JARVISTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'İsim girin',
                labelStyle: TextStyle(color: JARVISTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: JARVISTheme.hologram,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _run('search_contacts', {'query': controller.text}, 'rehber');
              },
              child: const Text('ARA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
