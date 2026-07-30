import '../models/message.dart';

class CommunicationService {
  final List<JarvisMessage> _messages = [];

  List<JarvisMessage> get messages => List.unmodifiable(_messages);
  List<JarvisMessage> get unreadMessages => _messages.where((m) => !m.isRead).toList();
  List<JarvisMessage> get urgentMessages => _messages.where((m) => m.isUrgent).toList();

  void addMessage(String sender, String content, MessageType type, {bool isUrgent = false}) {
    _messages.insert(0, JarvisMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: sender,
      content: content,
      timestamp: DateTime.now(),
      type: type,
      isUrgent: isUrgent,
    ));
  }

  void markAsRead(String id) {
    final msg = _messages.firstWhere((m) => m.id == id);
    msg.isRead = true;
  }

  void sendEmail(String to, String subject, String body) {
    addMessage('Giden Kutusu', 'E-posta gönderildi: $subject', MessageType.email);
  }

  void sendSms(String to, String message) {
    addMessage('Giden Kutusu', 'Mesaj gönderildi: $message', MessageType.sms);
  }

  void scheduleReminder(String title, DateTime time) {
    addMessage('Hatırlatıcı', '$title - ${time.hour}:${time.minute.toString().padLeft(2, "0")}', MessageType.notification);
  }

  String greetBasedOnTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın Efendim';
    if (hour < 18) return 'Tünaydın Efendim';
    return 'İyi akşamlar Efendim';
  }
}
