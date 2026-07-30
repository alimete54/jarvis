enum SecurityAlert { intrusion, breach, anomaly, threat, scan }

class SecurityService {
  bool _isFirewallActive = true;
  bool _isEncryptionEnabled = true;
  int _intrusionAttempts = 0;
  final List<Map<String, dynamic>> _alerts = [];

  bool get isFirewallActive => _isFirewallActive;
  bool get isEncryptionEnabled => _isEncryptionEnabled;
  int get intrusionAttempts => _intrusionAttempts;
  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);

  void toggleFirewall() {
    _isFirewallActive = !_isFirewallActive;
  }

  void toggleEncryption() {
    _isEncryptionEnabled = !_isEncryptionEnabled;
  }

  void detectIntrusion() {
    _intrusionAttempts++;
    _alerts.insert(0, {
      'type': SecurityAlert.intrusion,
      'time': DateTime.now(),
      'message': 'İzinsiz giriş denemesi tespit edildi #$_intrusionAttempts',
      'severity': _intrusionAttempts > 5 ? 'CRITICAL' : 'WARNING',
    });
  }

  void scanNetwork() {
    _alerts.insert(0, {
      'type': SecurityAlert.scan,
      'time': DateTime.now(),
      'message': 'Ağ taraması tamamlandı: güvenlik açığı bulunamadı',
      'severity': 'INFO',
    });
  }

  void blockThreat(String threatIp) {
    _alerts.insert(0, {
      'type': SecurityAlert.threat,
      'time': DateTime.now(),
      'message': 'Tehdit bloke edildi: $threatIp',
      'severity': 'HIGH',
    });
  }

  String get securityStatus {
    if (_intrusionAttempts == 0 && _isFirewallActive) return 'GÜVENLİ';
    if (_intrusionAttempts < 3) return 'DÜŞÜK RİSK';
    if (_intrusionAttempts < 10) return 'ORTA RİSK';
    return 'YÜKSEK RİSK';
  }
}
