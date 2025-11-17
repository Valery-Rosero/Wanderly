import 'package:wanderly/data/datasources/local/chat_history_local_data_source.dart';
import 'package:wanderly/data/datasources/local/favorites_local_data_source.dart';
import 'package:wanderly/data/datasources/remote/gemini_remote_data_source.dart';
import 'package:wanderly/data/datasources/remote/places_remote_data_source.dart';
import 'package:wanderly/domain/entities/place_entity.dart';
import 'package:wanderly/domain/entities/chat_message_entity.dart';
import 'package:wanderly/domain/repositories/chat_repository.dart';
import 'package:wanderly/data/datasources/remote/chat_remote_data_source.dart';
import 'package:wanderly/domain/entities/chat_session_entity.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiRemoteDataSource _geminiDataSource;
  final PlacesRemoteDataSource _placesDataSource;
  final FavoritesLocalDataSource? _favoritesLocal;
  final ChatHistoryLocalDataSource? _historyLocal;
  final String _userId;
  final ChatRemoteDataSource? _chatRemote;
  String? _currentSessionId;

  ChatRepositoryImpl({
    required GeminiRemoteDataSource geminiDataSource,
    required PlacesRemoteDataSource placesDataSource,
    FavoritesLocalDataSource? favoritesLocal,
    ChatHistoryLocalDataSource? historyLocal,
    required String userId,
    ChatRemoteDataSource? chatRemoteDataSource,
  }) : _geminiDataSource = geminiDataSource,
       _placesDataSource = placesDataSource,
       _favoritesLocal = favoritesLocal,
       _historyLocal = historyLocal,
       _userId = userId,
       _chatRemote = chatRemoteDataSource;

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
    // Local (móvil) como antes
    if (_historyLocal == null) {
      // Web: sin local, continuamos para remoto
    } else {
      final msg = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: isUser,
        timestamp: timestamp,
        placeType: placeType,
      );
      await _historyLocal.addMessage(userId, msg);
    }

    // Remoto: guardar en Supabase dentro de la sesión actual (crea si no existe)
    if (_chatRemote != null) {
      if (_currentSessionId == null) {
        final title = _buildSessionTitle(content);
        _currentSessionId = await _chatRemote!.createSession(
          userId: _userId,
          title: title,
        );
      }
      await _chatRemote!.addMessage(
        sessionId: _currentSessionId!,
        isUser: isUser,
        content: content,
        placeType: placeType,
      );
    }
  }

  @override
  Future<String> startNewSession({
    required String userId,
    String? title,
  }) async {
    if (_chatRemote == null) {
      // Sin remoto: simplemente resetea el contexto local
      _currentSessionId = null;
      return 'local';
    }
    final t = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'Nueva conversación';
    final id = await _chatRemote!.createSession(userId: userId, title: t);
    _currentSessionId = id;
    return id;
  }

  @override
  Future<List<ChatSessionEntity>> listChatSessions({
    required String userId,
  }) async {
    if (_chatRemote == null) return [];
    final raw = await _chatRemote!.listSessions(userId);
    return raw.map((r) {
      return ChatSessionEntity(
        id: r['id'].toString(),
        title: r['title']?.toString() ?? 'Conversación',
        createdAt: DateTime.parse(r['created_at'].toString()),
        lastMessageAt: r['last_message_at'] != null
            ? DateTime.parse(r['last_message_at'].toString())
            : null,
        isArchived: (r['is_archived'] ?? false) == true,
      );
    }).toList();
  }

  @override
  Future<List<ChatMessageEntity>> getSessionMessages({
    required String sessionId,
    int limit = 200,
  }) async {
    if (_chatRemote == null) return [];
    final raw = await _chatRemote!.getMessages(
      sessionId: sessionId,
      limit: limit,
    );
    return raw.map((m) {
      final isUser = (m['role']?.toString() ?? 'user') == 'user';
      return ChatMessageEntity(
        id: m['id'].toString(),
        content: m['content']?.toString() ?? '',
        isUser: isUser,
        timestamp: DateTime.parse(m['created_at'].toString()),
        placeType: m['place_type']?.toString(),
      );
    }).toList();
  }

  String _buildSessionTitle(String firstMessage) {
    final t = firstMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length > 60 ? '${t.substring(0, 57)}…' : t;
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

  @override
  Future<void> deleteSession({required String sessionId}) async {
    if (_chatRemote == null) return;
    await _chatRemote!.deleteSession(sessionId);
    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
    }
  }

  @override
  Future<void> deleteAllSessions({required String userId}) async {
    if (_chatRemote == null) return;
    await _chatRemote!.deleteAllSessions(userId);
    _currentSessionId = null;
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
