enum MessageType { email, sms, call, notification, system }

class JarvisMessage {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  bool isRead;
  final bool isUrgent;

  JarvisMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.isUrgent = false,
  });
}
