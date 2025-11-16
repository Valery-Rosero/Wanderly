class ChatMessageEntity {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? placeType; 

  ChatMessageEntity({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.placeType,
  });
}