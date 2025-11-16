import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';

abstract class ChatRepository {
  Future<String> sendMessage({
    required String message,
    required double latitude,
    required double longitude,
  });
  
  Future<void> saveFavoritePlace(PlaceEntity place);
  Future<List<PlaceEntity>> getFavoritePlaces();

  // Chat history (local only)
  Future<void> saveChatMessage({
    required String userId,
    required String content,
    required bool isUser,
    required DateTime timestamp,
    String? placeType,
  });

  Future<List<ChatMessageEntity>> getChatHistory({
    required String userId,
    int limit,
  });

  Future<void> clearChatHistory({
    required String userId,
  });
}