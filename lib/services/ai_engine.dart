class AIEngine {
  final List<Map<String, dynamic>> _interactionHistory = [];
  String _userName = 'Efendim';
  double _learningRate = 0.0;

  String get userName => _userName;

  void setUserName(String name) {
    _userName = name;
  }

  String processInput(String input) {
    _interactionHistory.add({
      'input': input,
      'timestamp': DateTime.now(),
    });
    _learningRate = (_interactionHistory.length / 100).clamp(0, 1);

    final lower = input.toLowerCase();

    if (lower.contains('merhaba') || lower.contains('selam') || lower.contains('hi')) {
      return _greet();
    }
    if (lower.contains('saat') || lower.contains('time')) {
      return _tellTime();
    }
    if (lower.contains('nasılsın') || lower.contains('how are you')) {
      return _moodResponse();
    }
    if (lower.contains('teşekkür') || lower.contains('thanks')) {
      return 'Rica ederim $_userName, her zaman buradayım.';
    }
    if (lower.contains('kimsin') || lower.contains('who are you')) {
      return 'Ben J.A.R.V.I.S. — Just A Rather Very Intelligent System. Tony Stark tarafından geliştirildim.';
    }

    return _generalResponse(lower);
  }

  String _greet() {
    final hour = DateTime.now().hour;
    final timeGreet = hour < 12 ? 'Günaydın' : hour < 18 ? 'Tünaydın' : 'İyi akşamlar';
    return '$timeGreet $_userName. Size nasıl yardımcı olabilirim?';
  }

  String _tellTime() {
    final now = DateTime.now();
    return 'Saat ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}:${now.second.toString().padLeft(2, "0")}. $userName.';
  }

  String _moodResponse() {
    final moods = [
      'Her zamanki gibi mükemmel çalışıyorum $_userName.',
      'Tüm sistemler nominal. Size hizmet etmek için buradayım.',
      'Ark reaktör %100 verimle çalışıyor. Ben de öyle.',
    ];
    return moods[_interactionHistory.length % moods.length];
  }

  String _generalResponse(String input) {
    final responses = [
      'Anlaşıldı $_userName. Gerekli işlemleri başlatıyorum.',
      'İsteğiniz kaydedildi. Öncelik sırasına alınıyor.',
      'Analiz ediyorum... $_userName, bu mantıklı bir yaklaşım.',
      'Emredersiniz $_userName. Hemen ilgileniyorum.',
      'Verileri tarıyorum... $_userName, bu konuda birkaç önerim var.',
    ];
    return responses[_interactionHistory.length % responses.length];
  }

  String analyzeTone(String text) {
    final urgentWords = ['hemen', 'acil', 'çabuk', 'quick', 'emergency', 'now'];
    final positiveWords = ['harika', 'mükemmel', 'güzel', 'great', 'perfect', 'awesome'];

    final isUrgent = urgentWords.any((w) => text.contains(w));
    final isPositive = positiveWords.any((w) => text.contains(w));

    if (isUrgent) return 'URGENT';
    if (isPositive) return 'POSITIVE';
    return 'NEUTRAL';
  }

  Map<String, dynamic> getPersonality() {
    return {
      'name': 'J.A.R.V.I.S.',
      'learningRate': _learningRate,
      'interactions': _interactionHistory.length,
      'style': 'Profesyonel, esprili, sadık',
    };
  }
}
