import 'package:wanderly/domain/entities/place_entity.dart';
import 'package:wanderly/domain/entities/chat_message_entity.dart';

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

  Future<void> clearChatHistory({required String userId});
}
