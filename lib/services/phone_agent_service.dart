class Contact {
  final String id;
  final String name;
  final String phone;
  final String? email;

  Contact({required this.id, required this.name, required this.phone, this.email});
}

enum AgentTaskType {
  sms, call, contact, notification, setting, app, clipboard, battery, wifi, bluetooth
}

class AgentTask {
  final String id;
  final AgentTaskType type;
  final String description;
  bool isCompleted;
  final DateTime createdAt;

  AgentTask({
    required this.id,
    required this.type,
    required this.description,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class PhoneAgentService {
  final List<Contact> _contacts = [];
  final List<AgentTask> _taskHistory = [];
  bool _isWifiOn = true;
  bool _isBluetoothOn = false;
  double _screenBrightness = 0.8;
  double _volume = 0.5;
  bool _isDndOn = false;
  String _lastClipboard = '';

  PhoneAgentService() {
    _initContacts();
  }

  void _initContacts() {
    _contacts.addAll([
      Contact(id: '1', name: 'Pepper Potts', phone: '+1-555-0101', email: 'pepper@stark.com'),
      Contact(id: '2', name: 'Happy Hogan', phone: '+1-555-0102', email: 'happy@stark.com'),
      Contact(id: '3', name: 'Rhodey', phone: '+1-555-0103', email: 'rhodey@us.af.mil'),
      Contact(id: '4', name: 'Bruce Banner', phone: '+1-555-0104', email: 'bruce@avengers.org'),
      Contact(id: '5', name: 'Nick Fury', phone: '+1-555-0001', email: 'fury@shield.gov'),
    ]);
  }

  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<AgentTask> get taskHistory => List.unmodifiable(_taskHistory);
  bool get isWifiOn => _isWifiOn;
  bool get isBluetoothOn => _isBluetoothOn;
  double get screenBrightness => _screenBrightness;
  double get volume => _volume;
  bool get isDndOn => _isDndOn;
  String get lastClipboard => _lastClipboard;

  String sendSms(String contactName, String message) {
    final contact = _contacts.firstWhere(
      (c) => c.name.toLowerCase().contains(contactName.toLowerCase()),
      orElse: () => Contact(id: '0', name: contactName, phone: 'Bilinmiyor'),
    );
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.sms,
      description: 'SMS → ${contact.name}: "$message"',
      isCompleted: true,
    ));
    return 'SMS gönderildi: ${contact.name} → "$message"';
  }

  String callContact(String contactName) {
    final contact = _contacts.firstWhere(
      (c) => c.name.toLowerCase().contains(contactName.toLowerCase()),
      orElse: () => Contact(id: '0', name: contactName, phone: 'Bilinmiyor'),
    );
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.call,
      description: 'Arama başlatıldı: ${contact.name} (${contact.phone})',
      isCompleted: true,
    ));
    return '${contact.name} aranıyor... (${contact.phone})';
  }

  String addContact(String name, String phone) {
    final id = (_contacts.length + 1).toString();
    _contacts.add(Contact(id: id, name: name, phone: phone));
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.contact,
      description: 'Rehbere eklendi: $name ($phone)',
      isCompleted: true,
    ));
    return '$name rehbere eklendi.';
  }

  Contact? findContact(String query) {
    try {
      return _contacts.firstWhere(
        (c) => c.name.toLowerCase().contains(query.toLowerCase()) ||
               c.phone.contains(query),
      );
    } catch (_) {
      return null;
    }
  }

  String toggleWifi() {
    _isWifiOn = !_isWifiOn;
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.wifi,
      description: 'Wi-Fi ${_isWifiOn ? "açıldı" : "kapatıldı"}',
      isCompleted: true,
    ));
    return 'Wi-Fi ${_isWifiOn ? "açıldı" : "kapatıldı"}';
  }

  String toggleBluetooth() {
    _isBluetoothOn = !_isBluetoothOn;
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.bluetooth,
      description: 'Bluetooth ${_isBluetoothOn ? "açıldı" : "kapatıldı"}',
      isCompleted: true,
    ));
    return 'Bluetooth ${_isBluetoothOn ? "açıldı" : "kapatıldı"}';
  }

  String setBrightness(double level) {
    _screenBrightness = level.clamp(0.0, 1.0);
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.setting,
      description: 'Parlaklık %${(_screenBrightness * 100).toStringAsFixed(0)} olarak ayarlandı',
      isCompleted: true,
    ));
    return 'Parlaklık %${(_screenBrightness * 100).toStringAsFixed(0)}';
  }

  String setVolume(double level) {
    _volume = level.clamp(0.0, 1.0);
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.setting,
      description: 'Ses %${(_volume * 100).toStringAsFixed(0)}',
      isCompleted: true,
    ));
    return 'Ses seviyesi %${(_volume * 100).toStringAsFixed(0)}';
  }

  String toggleDnd() {
    _isDndOn = !_isDndOn;
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.setting,
      description: 'Rahatsız Etmeyin ${_isDndOn ? "açıldı" : "kapatıldı"}',
      isCompleted: true,
    ));
    return 'Rahatsız Etmeyin ${_isDndOn ? "aktif" : "pasif"}';
  }

  String copyToClipboard(String text) {
    _lastClipboard = text;
    _taskHistory.insert(0, AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AgentTaskType.clipboard,
      description: 'Panoya kopyalandı: "$text"',
      isCompleted: true,
    ));
    return 'Metin panoya kopyalandı.';
  }

  String getBatteryStatus() {
    final level = 40 + (DateTime.now().second % 60);
    return 'Pil seviyesi: %$level${level < 20 ? " — Düşük pil!" : ""}';
  }

  String executeCommand(String command) {
    final lower = command.toLowerCase();

    if (lower.contains('ara') || lower.contains('call')) {
      final name = command.replaceAll(RegExp(r'(ara|call| |\?)', caseSensitive: false), '').trim();
      return name.isNotEmpty ? callContact(name) : 'Kimi aramalıyım?';
    }
    if (lower.contains('mesaj') || lower.contains('sms') || lower.contains('send')) {
      final parts = command.split(RegExp(r' (to|de|ye|e) '));
      if (parts.length >= 2) {
        final name = parts.last.split(' ').first;
        final msg = parts.last.split(' ').skip(1).join(' ');
        return sendSms(parts.last, command.replaceAll(RegExp(r'.*(mesaj|sms|send).*?(to|de|ye|e) ', caseSensitive: false), ''));
      }
      if (parts.isNotEmpty) {
        return sendSmtWithAI(command);
      }
      return 'Kime mesaj göndereyim?';
    }
    if (lower.contains('wifi') || lower.contains('wi-fi')) {
      return toggleWifi();
    }
    if (lower.contains('bluetooth')) {
      return toggleBluetooth();
    }
    if (lower.contains('parlak') || lower.contains('brightness')) {
      final match = RegExp(r'(\d+)').firstMatch(lower);
      final level = match != null ? double.parse(match.group(1)!) / 100 : 0.5;
      return setBrightness(level);
    }
    if (lower.contains('ses') || lower.contains('volume')) {
      final match = RegExp(r'(\d+)').firstMatch(lower);
      final level = match != null ? double.parse(match.group(1)!) / 100 : 0.5;
      return setVolume(level);
    }
    if (lower.contains('rahatsız') || lower.contains('dnd') || lower.contains('sessiz')) {
      return toggleDnd();
    }
    if (lower.contains('rehber') || lower.contains('contact') || lower.contains('kişi')) {
      return 'Rehberde ${_contacts.length} kişi var. Kimi bulmak istersiniz?';
    }
    if (lower.contains('pil') || lower.contains('battery')) {
      return getBatteryStatus();
    }
    if (lower.contains('kopyala') || lower.contains('copy')) {
      final text = command.replaceAll(RegExp(r'(kopyala|copy| |\?)', caseSensitive: false), '').trim();
      return text.isNotEmpty ? copyToClipboard(text) : 'Ne kopyalamalıyım?';
    }

    return 'Anlaşılamadı. Kullanılabilir komutlar: ara [kişi], mesaj [kişi] [metin], wifi, bluetooth, parlaklık [0-100], ses [0-100], sessiz, pil, rehber, kopyala [metin]';
  }

  String sendSmtWithAI(String command) {
    final words = command.split(' ');
    if (words.length < 3) return 'Kime ve ne mesajı göndereyim?';
    final name = words[1];
    final msg = words.skip(2).join(' ');
    return sendSms(name, msg);
  }
}
