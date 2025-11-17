class ChatSessionEntity {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final bool isArchived;

  ChatSessionEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    this.lastMessageAt,
    this.isArchived = false,
  });
}
