import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/phone_agent_service.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController _cmdController = TextEditingController();
  String _selectedMode = 'komut';

  @override
  void dispose() {
    _cmdController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            _buildHeader(),
            _buildModeBar(),
            Expanded(
              child: _selectedMode == 'komut'
                  ? _buildCommandCenter(vm)
                  : _buildPhoneStatus(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
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
              Text('TELEFON AJANI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3, color: JARVISTheme.textPrimary)),
              Text('Kontrol • Yönetim • Otomasyon', style: TextStyle(fontSize: 11, color: JARVISTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ModeChip(label: 'AKILLI KOMUT', isActive: _selectedMode == 'komut', onTap: () => setState(() => _selectedMode = 'komut')),
          const SizedBox(width: 10),
          _ModeChip(label: 'DURUM', isActive: _selectedMode == 'durum', onTap: () => setState(() => _selectedMode = 'durum')),
        ],
      ),
    );
  }

  Widget _buildCommandCenter(JARVISViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(vm),
          const SizedBox(height: 20),
          _buildCommandInput(vm),
          const SizedBox(height: 20),
          _buildTaskHistory(vm),
        ],
      ),
    );
  }

  Widget _buildQuickActions(JARVISViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HIZLI İŞLEMLER', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AgentAction(
              icon: Icons.wifi,
              label: 'Wi-Fi ${vm.phoneAgentService.isWifiOn ? "AÇIK" : "KAPALI"}',
              color: vm.phoneAgentService.isWifiOn ? JARVISTheme.primary : JARVISTheme.textSecondary,
              onTap: () { vm.phoneAgentService.toggleWifi(); setState(() {}); },
            ),
            _AgentAction(
              icon: Icons.bluetooth,
              label: 'BT ${vm.phoneAgentService.isBluetoothOn ? "AÇIK" : "KAPALI"}',
              color: vm.phoneAgentService.isBluetoothOn ? JARVISTheme.primary : JARVISTheme.textSecondary,
              onTap: () { vm.phoneAgentService.toggleBluetooth(); setState(() {}); },
            ),
            _AgentAction(
              icon: Icons.do_not_disturb_alt,
              label: vm.phoneAgentService.isDndOn ? 'SESSİZ' : 'NORMAL',
              color: vm.phoneAgentService.isDndOn ? JARVISTheme.warning : JARVISTheme.textSecondary,
              onTap: () { vm.phoneAgentService.toggleDnd(); setState(() {}); },
            ),
            _AgentAction(
              icon: Icons.contacts,
              label: 'REHBER (${vm.phoneAgentService.contacts.length})',
              color: JARVISTheme.hologram,
              onTap: () => _showContacts(vm),
            ),
            _AgentAction(
              icon: Icons.battery_std,
              label: 'PİL',
              color: JARVISTheme.success,
              onTap: () {
                final result = vm.phoneAgentService.getBatteryStatus();
                vm.sendCommand(result);
                setState(() {});
              },
            ),
            _AgentAction(
              icon: Icons.brightness_6,
              label: 'PARLAKLIK',
              color: JARVISTheme.warning,
              onTap: () => _showBrightnessSlider(vm),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandInput(JARVISViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KOMUT GİRİŞİ', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: JARVISTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JARVISTheme.surfaceLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cmdController,
                  style: const TextStyle(color: JARVISTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Örn: "Pepper\'ı ara" veya "mesaj gönder"',
                    hintStyle: TextStyle(color: JARVISTheme.textSecondary, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      vm.executeAgentCommand(val);
                      _cmdController.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_cmdController.text.isNotEmpty) {
                    vm.executeAgentCommand(_cmdController.text);
                    _cmdController.clear();
                    setState(() {});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: JARVISTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send, color: JARVISTheme.secondary, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskHistory(JARVISViewModel vm) {
    final tasks = vm.phoneAgentService.taskHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GÖREV GEÇMİŞİ', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
            Text('${tasks.length} kayıt', style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: JARVISTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JARVISTheme.surfaceLight),
            ),
            child: const Center(
              child: Text('Henüz işlem yapılmadı', style: TextStyle(color: JARVISTheme.textSecondary)),
            ),
          )
        else
          ...tasks.take(10).map((task) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: JARVISTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: JARVISTheme.surfaceLight),
            ),
            child: Row(
              children: [
                _taskIcon(task.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(task.description, style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 12)),
                ),
                Icon(Icons.check_circle, color: JARVISTheme.success.withOpacity(0.5), size: 14),
              ],
            ),
          )),
      ],
    );
  }

  Widget _taskIcon(dynamic type) {
    IconData icon;
    Color color;
    switch (type) {
      case AgentTaskType.sms: icon = Icons.sms; color = JARVISTheme.primary;
      case AgentTaskType.call: icon = Icons.phone; color = JARVISTheme.success;
      case AgentTaskType.contact: icon = Icons.person_add; color = JARVISTheme.hologram;
      case AgentTaskType.wifi: icon = Icons.wifi; color = JARVISTheme.primary;
      case AgentTaskType.bluetooth: icon = Icons.bluetooth; color = JARVISTheme.primary;
      case AgentTaskType.setting: icon = Icons.settings; color = JARVISTheme.warning;
      default: icon = Icons.touch_app; color = JARVISTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildPhoneStatus(JARVISViewModel vm) {
    final p = vm.phoneAgentService;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [JARVISTheme.surface, JARVISTheme.surfaceLight.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JARVISTheme.surfaceLight),
            ),
            child: Column(
              children: [
                const Text('TELEFON DURUMU', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 16),
                _StatusRow(icon: Icons.wifi, label: 'Wi-Fi', value: p.isWifiOn ? 'BAĞLI' : 'KAPALI', color: p.isWifiOn ? JARVISTheme.primary : JARVISTheme.textSecondary),
                const SizedBox(height: 10),
                _StatusRow(icon: Icons.bluetooth, label: 'Bluetooth', value: p.isBluetoothOn ? 'AÇIK' : 'KAPALI', color: p.isBluetoothOn ? JARVISTheme.primary : JARVISTheme.textSecondary),
                const SizedBox(height: 10),
                _StatusRow(icon: Icons.brightness_6, label: 'Parlaklık', value: '%${(p.screenBrightness * 100).toStringAsFixed(0)}', color: JARVISTheme.warning),
                const SizedBox(height: 10),
                _StatusRow(icon: Icons.volume_up, label: 'Ses', value: '%${(p.volume * 100).toStringAsFixed(0)}', color: JARVISTheme.primary),
                const SizedBox(height: 10),
                _StatusRow(icon: Icons.do_not_disturb_alt, label: 'Rahatsız Etmeyin', value: p.isDndOn ? 'AKTİF' : 'PASİF', color: p.isDndOn ? JARVISTheme.warning : JARVISTheme.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JARVISTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JARVISTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REHBER', style: TextStyle(color: JARVISTheme.textSecondary, fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 10),
                ...p.contacts.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: JARVISTheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.person, color: JARVISTheme.secondary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13)),
                            Text(c.phone, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContacts(JARVISViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: JARVISTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REHBER', style: TextStyle(color: JARVISTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 16),
            ...vm.phoneAgentService.contacts.map((c) => ListTile(
              leading: CircleAvatar(
                backgroundColor: JARVISTheme.secondary.withOpacity(0.2),
                child: Text(c.name[0], style: const TextStyle(color: JARVISTheme.secondary)),
              ),
              title: Text(c.name, style: const TextStyle(color: JARVISTheme.textPrimary)),
              subtitle: Text(c.phone, style: const TextStyle(color: JARVISTheme.textSecondary)),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  void _showBrightnessSlider(JARVISViewModel vm) {
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
              const Text('PARLAKLIK KONTROLÜ', style: TextStyle(color: JARVISTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.brightness_low, color: JARVISTheme.textSecondary),
                  Expanded(
                    child: Slider(
                      value: vm.phoneAgentService.screenBrightness,
                      activeColor: JARVISTheme.warning,
                      inactiveColor: JARVISTheme.surfaceLight,
                      onChanged: (val) {
                        vm.phoneAgentService.setBrightness(val);
                        setSheetState(() {});
                      },
                    ),
                  ),
                  const Icon(Icons.brightness_high, color: JARVISTheme.textSecondary),
                ],
              ),
              Text('%${(vm.phoneAgentService.screenBrightness * 100).toStringAsFixed(0)}', style: const TextStyle(color: JARVISTheme.warning, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AgentAction({required this.icon, required this.label, required this.color, required this.onTap});

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
              Text(label, style: TextStyle(color: color, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 13))),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ],
    );
  }
}
