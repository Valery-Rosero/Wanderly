import 'package:flutter_application_movile/domain/entities/chat_message_entity.dart';

class ChatMessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? placeType;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.placeType,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      content: json['content'],
      isUser: json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
      placeType: json['place_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'place_type': placeType,
    };
  }

  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      placeType: placeType,
    );
  }
}
