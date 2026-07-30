import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../viewmodels/jarvis_viewmodel.dart';
import 'widgets/voice_command_bar.dart';
import 'widgets/device_control_tile.dart';

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
                      _buildQuickActions(vm),
                      const SizedBox(height: 16),
                      _buildActiveDevices(vm),
                    ],
                  ),
                ),
              ),
              VoiceCommandBar(
                onCommand: (cmd) => vm.sendCommand(cmd),
                isProcessing: vm.isProcessing,
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
              Text('J.A.R.V.I.S.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3, color: JARVISTheme.textPrimary)),
              Text('Just A Rather Very Intelligent System', style: TextStyle(fontSize: 10, color: JARVISTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          _buildSystemStatus(),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: JARVISTheme.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JARVISTheme.success.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: JARVISTheme.success, size: 14),
          SizedBox(width: 6),
          Text('SİSTEM AKTİF', style: TextStyle(color: JARVISTheme.success, fontSize: 10, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(JARVISViewModel vm) {
    final p = vm.phoneAgentService;
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
          value: p.isWifiOn ? 'BAĞLI' : 'ÇEVRİMDIŞI',
          color: JARVISTheme.secondary,
          sub: 'Wi-Fi: ${p.isWifiOn ? "AÇIK" : "KAPALI"} • BT: ${p.isBluetoothOn ? "AÇIK" : "KAPALI"}',
        ),
        _StatusCard(
          icon: Icons.security_outlined,
          label: 'GÜVENLİK',
          value: vm.securityService.securityStatus,
          color: vm.securityService.intrusionAttempts > 0 ? JARVISTheme.warning : JARVISTheme.success,
          sub: 'Güvenlik duvarı: ${vm.securityService.isFirewallActive ? "AKTİF" : "PASİF"}',
        ),
        _StatusCard(
          icon: Icons.chat_outlined,
          label: 'İLETİŞİM',
          value: '${vm.communicationService.unreadMessages.length} OKUNMAMIŞ',
          color: JARVISTheme.primary,
          sub: 'Son: ${vm.communicationService.messages.isNotEmpty ? vm.communicationService.messages.first.sender : "YOK"}',
        ),
        _StatusCard(
          icon: Icons.devices_outlined,
          label: 'BAĞLI CİHAZLAR',
          value: '${vm.homeKitService.activeDevices.length} AKTİF',
          color: JARVISTheme.secondary,
          sub: 'Toplam ${vm.homeKitService.devices.length} cihaz',
        ),
      ],
    );
  }

  Widget _buildQuickActions(JARVISViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HIZLI İŞLEMLER', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionChip(icon: Icons.nightlight_round, label: 'Işıkları Kapa', onTap: () => vm.sendCommand('ışıkları kapat')),
            _ActionChip(icon: Icons.wifi, label: 'Wi-Fi Aç/Kapa', onTap: () => vm.executeAgentCommand('wifi')),
            _ActionChip(icon: Icons.phone, label: 'Pepper\'ı Ara', onTap: () => vm.executeAgentCommand('ara Pepper Potts')),
            _ActionChip(icon: Icons.security, label: 'Ağ Tara', onTap: () => vm.scanNetwork()),
            _ActionChip(icon: Icons.battery_std, label: 'Pil Durumu', onTap: () => vm.executeAgentCommand('pil')),
            _ActionChip(icon: Icons.do_not_disturb_alt, label: 'Sessiz Mod', onTap: () => vm.executeAgentCommand('sessiz')),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveDevices(JARVISViewModel vm) {
    final devices = vm.homeKitService.devices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AKTİF CİHAZLAR', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        ...devices.take(4).map((device) => DeviceControlTile(
          device: device,
          onToggle: () => vm.homeKitService.toggleDevice(device.id),
        )),
      ],
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
              Text(label, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 9, letterSpacing: 1.5)),
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
              Text(label, style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 12, letterSpacing: 1)),
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
