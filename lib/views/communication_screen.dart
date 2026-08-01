import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../viewmodels/jarvis_viewmodel.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  List<Contact> _contacts = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status =
          await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        setState(() {
          _error = 'Rehber izni verilmedi. Ayarlar > Gizlilik > Kişilerden izin verin.';
          _loading = false;
        });
        return;
      }
      final contacts = await FlutterContacts.getAll(
          properties: ContactProperties.allProperties);
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Rehber okunamadı: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JARVISViewModel>();

    final filtered = _query.isEmpty
        ? _contacts
        : _contacts
            .where((c) => (c.displayName ?? '')
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Kişi ara...',
                  hintStyle: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: JARVISTheme.textSecondary, size: 18),
                  filled: true,
                  fillColor: JARVISTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: JARVISTheme.surfaceLight),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(JARVISViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: JARVISTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat, color: JARVISTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('İLETİŞİM',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3, color: JARVISTheme.textPrimary)),
              Text('Rehber • Arama • Mesaj',
                  style: TextStyle(fontSize: 11, color: JARVISTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: JARVISTheme.primary, size: 20),
            onPressed: _loadContacts,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Contact> contacts) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: JARVISTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: JARVISTheme.warning, size: 40),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    if (contacts.isEmpty) {
      return const Center(
        child: Text('Rehberde kişi yok.',
            style: TextStyle(color: JARVISTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : null;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: JARVISTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JARVISTheme.surfaceLight),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: JARVISTheme.secondary.withOpacity(0.2),
                child: Text(
                  (contact.displayName?.isNotEmpty ?? false)
                      ? contact.displayName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: JARVISTheme.secondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact.displayName ?? '',
                        style: const TextStyle(color: JARVISTheme.textPrimary, fontSize: 13)),
                    Text(phone ?? 'Telefon yok',
                        style: const TextStyle(color: JARVISTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              if (phone != null) ...[
                IconButton(
                  icon: const Icon(Icons.phone, color: JARVISTheme.success, size: 18),
                  onPressed: () => launchUrl(Uri.parse('tel:$phone'),
                      mode: LaunchMode.externalApplication),
                ),
                IconButton(
                  icon: const Icon(Icons.sms, color: JARVISTheme.primary, size: 18),
                  onPressed: () => _showSmsSheet(contact, phone),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showSmsSheet(Contact contact, String phone) {
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
            Text('Mesaj: ${contact.displayName}',
                style: const TextStyle(
                    color: JARVISTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: JARVISTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mesajınız',
                labelStyle: TextStyle(color: JARVISTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: JARVISTheme.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(
                  Uri.parse('sms:$phone?body=${Uri.encodeComponent(controller.text)}'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('MESAJLARDA AÇ'),
            ),
          ],
        ),
      ),
    );
  }
}
