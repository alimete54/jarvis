import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

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
        child: Column(
          children: [
            _buildHeader(vm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecurityStatus(vm),
                    const SizedBox(height: 20),
                    _buildControls(vm),
                    const SizedBox(height: 20),
                    _buildAlertLog(vm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(JARVISViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: vm.securityService.securityStatus == 'GÜVENLİ'
                  ? JARVISTheme.success.withOpacity(0.15)
                  : JARVISTheme.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              vm.securityService.securityStatus == 'GÜVENLİ' ? Icons.security : Icons.warning,
              color: vm.securityService.securityStatus == 'GÜVENLİ' ? JARVISTheme.success : JARVISTheme.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GÜVENLİK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3, color: JARVISTheme.textPrimary)),
              Text('Siber Savunma • Tehdit Tespiti', style: TextStyle(fontSize: 11, color: JARVISTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatus(JARVISViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            vm.securityService.securityStatus == 'GÜVENLİ'
                ? JARVISTheme.success.withOpacity(0.1)
                : JARVISTheme.danger.withOpacity(0.1),
            JARVISTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vm.securityService.securityStatus == 'GÜVENLİ'
              ? JARVISTheme.success.withOpacity(0.2)
              : JARVISTheme.danger.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AĞ DURUMU', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
              Text(vm.securityService.securityStatus, style: TextStyle(
                color: vm.securityService.securityStatus == 'GÜVENLİ'
                    ? JARVISTheme.success
                    : JARVISTheme.danger,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              )),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Güvenlik Duvarı', vm.securityService.isFirewallActive ? 'AKTİF' : 'PASİF', vm.securityService.isFirewallActive ? JARVISTheme.success : JARVISTheme.danger),
          const SizedBox(height: 8),
          _buildStatRow('Şifreleme', vm.securityService.isEncryptionEnabled ? 'AKTİF' : 'PASİF', vm.securityService.isEncryptionEnabled ? JARVISTheme.success : JARVISTheme.danger),
          const SizedBox(height: 8),
          _buildStatRow('İzinsiz Giriş Denemesi', '${vm.securityService.intrusionAttempts}', vm.securityService.intrusionAttempts > 0 ? JARVISTheme.warning : JARVISTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildControls(JARVISViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KONTROLLER', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                icon: Icons.shield_outlined,
                label: 'Güvenlik Duvarı',
                isActive: vm.securityService.isFirewallActive,
                onTap: () => vm.securityService.toggleFirewall(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ControlButton(
                icon: Icons.lock_outline,
                label: 'Şifreleme',
                isActive: vm.securityService.isEncryptionEnabled,
                onTap: () => vm.securityService.toggleEncryption(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ControlButton(
            icon: Icons.wifi_tethering,
            label: 'AĞ TARAMASI YAP',
            isActive: false,
            onTap: () => vm.scanNetwork(),
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertLog(JARVISViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ALARM KAYITLARI', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 12),
        if (vm.securityService.alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: JARVISTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JARVISTheme.surfaceLight),
            ),
            child: const Center(
              child: Text('Temiz kayıt — tehdit yok', style: TextStyle(color: JARVISTheme.textSecondary)),
            ),
          )
        else
          ...vm.securityService.alerts.take(5).map((alert) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JARVISTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: alert['severity'] == 'CRITICAL'
                    ? JARVISTheme.danger.withOpacity(0.3)
                    : JARVISTheme.surfaceLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  alert['severity'] == 'CRITICAL' ? Icons.error : Icons.info_outline,
                  color: alert['severity'] == 'CRITICAL' ? JARVISTheme.danger : JARVISTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert['message'], style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 12)),
                      Text('${alert['time']}', style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: fullWidth ? 24 : 16),
          decoration: BoxDecoration(
            color: isActive ? JARVISTheme.primary.withOpacity(0.1) : JARVISTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? JARVISTheme.primary.withOpacity(0.3) : JARVISTheme.surfaceLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: isActive ? JARVISTheme.primary : JARVISTheme.textSecondary, size: 18),
              if (!fullWidth) const SizedBox(width: 10),
              if (!fullWidth)
                Expanded(
                  child: Text(label, style: TextStyle(
                    color: isActive ? JARVISTheme.textPrimary : JARVISTheme.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1,
                  )),
                ),
              if (fullWidth) const SizedBox(width: 10),
              if (fullWidth)
                Text(label, style: const TextStyle(color: JARVISTheme.primary, fontSize: 12, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
