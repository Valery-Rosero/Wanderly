import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

abstract class ChatRepository {
  Future<String> sendMessage({
    required String message,
    required double latitude,
    required double longitude,
  });
  
  Future<void> saveFavoritePlace(PlaceEntity place);
  Future<List<PlaceEntity>> getFavoritePlaces();
}