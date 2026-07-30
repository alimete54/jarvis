import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/message.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final TextEditingController _msgController = TextEditingController();
  String _selectedTab = 'mesajlar';

  @override
  void dispose() {
    _msgController.dispose();
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
            _buildTabBar(),
            Expanded(
              child: _selectedTab == 'mesajlar'
                  ? _buildMessages(vm)
                  : _buildQuickActions(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.chat_outlined, color: JARVISTheme.primary, size: 28),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('İLETİŞİM', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3, color: JARVISTheme.textPrimary)),
              Text('Bilgi Asistanı • Mesaj Yönetimi', style: TextStyle(fontSize: 11, color: JARVISTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabButton(label: 'MESAJLAR', isActive: _selectedTab == 'mesajlar', onTap: () => setState(() => _selectedTab = 'mesajlar')),
          const SizedBox(width: 12),
          _TabButton(label: 'HIZLI İŞLEMLER', isActive: _selectedTab == 'hizli', onTap: () => setState(() => _selectedTab = 'hizli')),
        ],
      ),
    );
  }

  Widget _buildMessages(JARVISViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: JARVISTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: const TextStyle(color: JARVISTheme.textSecondary),
                    filled: true,
                    fillColor: JARVISTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: JARVISTheme.primary.withOpacity(0.2)),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: JARVISTheme.primary),
                      onPressed: () {
                        if (_msgController.text.isNotEmpty) {
                          vm.communicationService.addMessage('Ben', _msgController.text, MessageType.sms);
                          vm.aiEngine.processInput(_msgController.text);
                          _msgController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vm.communicationService.messages.take(20).map((msg) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JARVISTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: msg.isUrgent ? JARVISTheme.danger.withOpacity(0.3) : JARVISTheme.surfaceLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: msg.sender == 'J.A.R.V.I.S.'
                        ? JARVISTheme.primary.withOpacity(0.15)
                        : JARVISTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    msg.type == MessageType.email ? Icons.email : Icons.chat_bubble_outline,
                    color: msg.sender == 'J.A.R.V.I.S.' ? JARVISTheme.primary : JARVISTheme.secondary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(msg.sender, style: const TextStyle(color: JARVISTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                          if (msg.isUrgent) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.warning, color: JARVISTheme.danger, size: 12),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(msg.content, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 12)),
                      Text(
                        '${msg.timestamp.hour.toString().padLeft(2, "0")}:${msg.timestamp.minute.toString().padLeft(2, "0")}',
                        style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickActions(JARVISViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _QuickActionTile(
            icon: Icons.email,
            label: 'E-posta Gönder',
            subtitle: 'Stark Industries',
            onTap: () => vm.communicationService.sendEmail('ekip@stark.com', 'Toplantı', 'Yarın saat 10:00'),
          ),
          const SizedBox(height: 8),
          _QuickActionTile(
            icon: Icons.sms,
            label: 'Mesaj Gönder',
            subtitle: 'Pepper Potts',
            onTap: () => vm.communicationService.sendSms('Pepper', 'Akşam yemeği için yer ayırttım.'),
          ),
          const SizedBox(height: 8),
          _QuickActionTile(
            icon: Icons.notifications_active,
            label: 'Hatırlatıcı Kur',
            subtitle: 'Proje teslim tarihi',
            onTap: () => vm.communicationService.scheduleReminder('Proje Teslimi', DateTime.now().add(const Duration(hours: 24))),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? JARVISTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: JARVISTheme.primary.withOpacity(0.3)) : null,
        ),
        child: Text(label, style: TextStyle(
          color: isActive ? JARVISTheme.primary : JARVISTheme.textSecondary,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        )),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JARVISTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JARVISTheme.surfaceLight),
          ),
          child: Row(
            children: [
              Icon(icon, color: JARVISTheme.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: JARVISTheme.textPrimary, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: JARVISTheme.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
