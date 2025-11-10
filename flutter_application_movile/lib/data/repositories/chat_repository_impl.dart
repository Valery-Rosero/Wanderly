import 'package:flutter_application_movile/data/datasources/remote/gemini_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/lugares_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/favorites_local_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/chat_history_local_data_source.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiRemoteDataSource _geminiDataSource;
  final PlacesRemoteDataSource _lugaresDataSource;
  final FavoritesLocalDataSource? _favoritesLocal;
  final ChatHistoryLocalDataSource? _historyLocal;
  final String _usuarioId;

  ChatRepositoryImpl({
    required GeminiRemoteDataSource geminiDataSource,
    required PlacesRemoteDataSource lugaresDataSource,
    FavoritesLocalDataSource? favoritesLocal,
    ChatHistoryLocalDataSource? historyLocal,
    required String usuarioId,
  })  : _geminiDataSource = geminiDataSource,
        _lugaresDataSource = lugaresDataSource,
        _favoritesLocal = favoritesLocal,
        _historyLocal = historyLocal,
        _usuarioId = usuarioId;

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
    required String contenido,
    required bool esUsuario,
    required DateTime timestamp,
    String? placeType,
  }) async {
    if (_historyLocal == null) return; // Web: no local storage
    final msg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contenido: contenido,
      esUsuario: esUsuario,
      timestamp: timestamp,
      placeType: placeType,
    );
    await _historyLocal!.addMessage(userId, msg);
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory({
    required String userId,
    int limit = 200,
  }) async {
    if (_historyLocal == null) return [];
    return _historyLocal!.getMessages(userId, limit: limit);
  }

  @override
  Future<void> clearChatHistory({
    required String userId,
  }) async {
    if (_historyLocal == null) return;
    await _historyLocal!.clearHistory(userId);
  }

  @override
  Future<void> saveFavoritePlace(PlaceEntity place) async {
    if (_favoritesLocal != null) {
      // Guarda localmente primero (offline-first)
      final localId = await _favoritesLocal!.saveFavorite(_usuarioId, place);
      // Intenta sincronizar con Supabase; si falla, encola
      try {
        await _lugaresDataSource.saveFavoritePlace(
          usuarioId: _usuarioId,
          nombreLugar: place.name,
          address: place.address,
          latitude: place.latitude,
          longitude: place.longitude,
          placeType: place.placeType,
          notas: 'Guardado desde chat',
        );
        await _favoritesLocal!.markFavoriteSynced(localId, place.id);
      } catch (_) {
        await _favoritesLocal!.enqueueSyncFavorite(_usuarioId, place);
      }
    } else {
      // Web u otros entornos sin SQLite: inserta directamente en Supabase
      await _lugaresDataSource.saveFavoritePlace(
        usuarioId: _usuarioId,
        nombreLugar: place.name,
        address: place.address,
        latitude: place.latitude,
        longitude: place.longitude,
        placeType: place.placeType,
        notas: 'Guardado desde chat',
      );
    }
  }

  @override
  Future<List<PlaceEntity>> getFavoritePlaces() async {
    if (_favoritesLocal != null) {
      // Devuelve favorites locales
      return _favoritesLocal!.getFavorites(_usuarioId);
    }
    // Fallback: leer de Supabase directamente en web
    final data = await _lugaresDataSource.getFavoritePlaces(_usuarioId);
    return data.map((json) {
      final coordenadas = _parseCoordenadas(json['coordenadas']);
      return PlaceEntity(
        id: json['id'],
        name: json['nombre_lugar'],
        address: json['direccion'] ?? '',
        latitude: coordenadas.$1,
        longitude: coordenadas.$2,
        placeType: json['tipo_lugar'] ?? '',
      );
    }).toList();
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