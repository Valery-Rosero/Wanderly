import 'package:wanderly/data/datasources/local/chat_history_local_data_source.dart';
import 'package:wanderly/data/datasources/local/favorites_local_data_source.dart';
import 'package:wanderly/data/datasources/remote/gemini_remote_data_source.dart';
import 'package:wanderly/data/datasources/remote/places_remote_data_source.dart';
import 'package:wanderly/domain/entities/place_entity.dart';
import 'package:wanderly/domain/entities/chat_message_entity.dart';
import 'package:wanderly/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiRemoteDataSource _geminiDataSource;
  final PlacesRemoteDataSource _placesDataSource;
  final FavoritesLocalDataSource? _favoritesLocal;
  final ChatHistoryLocalDataSource? _historyLocal;
  final String _userId;

  ChatRepositoryImpl({
    required GeminiRemoteDataSource geminiDataSource,
    required PlacesRemoteDataSource placesDataSource,
    FavoritesLocalDataSource? favoritesLocal,
    ChatHistoryLocalDataSource? historyLocal,
    required String userId,
  }) : _geminiDataSource = geminiDataSource,
       _placesDataSource = placesDataSource,
       _favoritesLocal = favoritesLocal,
       _historyLocal = historyLocal,
       _userId = userId;

  @override
  Future<String> sendMessage({
    required String message,
    required double latitude,
    required double longitude,
  }) async {
    return await _geminiDataSource.obtenerRecomendacion(
      message: message,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<void> saveChatMessage({
    required String userId,
    required String content,
    required bool isUser,
    required DateTime timestamp,
    String? placeType,
  }) async {
    if (_historyLocal == null) return; // Web: no local storage
    final msg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      placeType: placeType,
    );
    await _historyLocal.addMessage(userId, msg);
  }

  @override
  Future<void> saveFavoritePlace(PlaceEntity place) async {
    if (_favoritesLocal != null) {
      final localId = await _favoritesLocal.saveFavorite(_userId, place);
      try {
        final remoteId = await _placesDataSource.saveFavoritePlace(
          userId: _userId,
          placeName: place.name,
          address: place.address,
          latitude: place.latitude,
          longitude: place.longitude,
          placeType: place.placeType,
          notes: 'Guardado desde chat',
        );
        await _favoritesLocal.markFavoriteSynced(localId, remoteId);
      } catch (_) {
        await _favoritesLocal.enqueueSyncFavorite(_userId, place);
      }
    } else {
      await _placesDataSource.saveFavoritePlace(
        userId: _userId,
        placeName: place.name,
        address: place.address,
        latitude: place.latitude,
        longitude: place.longitude,
        placeType: place.placeType,
        notes: 'Guardado desde chat',
      );
    }
  }

  @override
  Future<List<PlaceEntity>> getFavoritePlaces() async {
    if (_favoritesLocal != null) {
      return _favoritesLocal.getFavorites(_userId);
    }
    final data = await _placesDataSource.getFavoritePlaces(_userId);
    return data.map((json) {
      final coordenadas = _parseCoordenadas(json['coordinates']);
      return PlaceEntity(
        id: json['id'].toString(),
        name: json['place_name'],
        address: json['address'] ?? '',
        latitude: coordenadas.$1,
        longitude: coordenadas.$2,
        placeType: json['place_type'] ?? '',
      );
    }).toList();
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory({
    required String userId,
    int limit = 200,
  }) async {
    if (_historyLocal == null) return [];
    return _historyLocal.getMessages(userId, limit: limit);
  }

  @override
  Future<void> clearChatHistory({required String userId}) async {
    if (_historyLocal == null) return;
    await _historyLocal.clearHistory(userId);
  }

  (double, double) _parseCoordenadas(String coordenadas) {
    // Parsear "POINT(lng lat)" de PostGIS
    final regex = RegExp(r'POINT\(([-\d.]+) ([-\d.]+)\)');
    final match = regex.firstMatch(coordenadas);
    if (match != null) {
      return (double.parse(match.group(2)!), double.parse(match.group(1)!));
    }
    return (0.0, 0.0);
  }
}
