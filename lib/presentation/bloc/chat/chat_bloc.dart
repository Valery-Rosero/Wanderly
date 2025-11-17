import 'dart:convert';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wanderly/domain/entities/place_entity.dart';
import 'package:wanderly/domain/entities/chat_message_entity.dart';
import 'package:wanderly/domain/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessageEntity> messages;
  final List<PlaceEntity> places;

  const ChatLoaded(this.messages, {this.places = const []});

  @override
  List<Object> get props => [messages, places];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

// Eventos
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadChatHistoryEvent extends ChatEvent {
  final String userId;
  final int limit;

  const LoadChatHistoryEvent({required this.userId, this.limit = 200});

  @override
  List<Object> get props => [userId, limit];
}

class SendMessageEvent extends ChatEvent {
  final String message;
  final double latitude;
  final double longitude;

  const SendMessageEvent({
    required this.message,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [message, latitude, longitude];
}

class SaveFavoritePlaceEvent extends ChatEvent {
  final PlaceEntity place;

  const SaveFavoritePlaceEvent(this.place);

  @override
  List<Object> get props => [place];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final List<ChatMessageEntity> _mensajes = [];
  List<PlaceEntity> _places = [];
  final String _userId;

  ChatBloc({required ChatRepository chatRepository, required String userId})
    : _chatRepository = chatRepository,
      _userId = userId,
      super(ChatInitial()) {
    on<SendMessageEvent>(_onEnviarMensaje);
    on<SaveFavoritePlaceEvent>(_onGuardarLugarFavorito);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
  }

  Future<void> _onEnviarMensaje(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Agregar message del user
    _mensajes.add(
      ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    // Persistir historial local en móvil
    if (!kIsWeb) {
      await _chatRepository.saveChatMessage(
        userId: _userId,
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );
    }
    // Mostrar estado de carga mientras la IA responde
    emit(ChatLoading());

    try {
      final respuesta = await _chatRepository.sendMessage(
        message: event.message,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      final visibleText = _stripJsonSuffix(respuesta);
      _mensajes.add(
        ChatMessageEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: visibleText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      if (!kIsWeb) {
        await _chatRepository.saveChatMessage(
          userId: _userId,
          content: visibleText,
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
      // Intentar extraer places del sufijo JSON_PLACES
      _places = _parsePlacesFromResponse(respuesta);
      // Enriquecer lugares con datos reales (teléfono, web, dirección) usando Nominatim
      if (_places.isNotEmpty) {
        _places = await _enrichPlacesWithRealData(
          _places,
          event.latitude,
          event.longitude,
        );
        // Filtro final por proximidad y país
        _places = _filterPlacesByProximity(
          _places,
          event.latitude,
          event.longitude,
        );
      }
      emit(ChatLoaded(List.from(_mensajes), places: List.from(_places)));
    } catch (e) {
      _mensajes.add(
        ChatMessageEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      emit(ChatLoaded(List.from(_mensajes), places: List.from(_places)));
    }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final history = await _chatRepository.getChatHistory(
        userId: event.userId,
        limit: event.limit,
      );
      _mensajes
        ..clear()
        ..addAll(history);
      emit(ChatLoaded(List.from(_mensajes), places: List.from(_places)));
    } catch (e) {
      emit(ChatError('No se pudo cargar historial: $e'));
    }
  }

  List<PlaceEntity> _parsePlacesFromResponse(String respuesta) {
    try {
      const marker = 'JSON_PLACES:';
      final idx = respuesta.lastIndexOf(marker);
      if (idx == -1) return [];
      final jsonLine = respuesta.substring(idx + marker.length).trim();
      final decoded = jsonDecode(jsonLine) as Map<String, dynamic>;
      final places = decoded['places'] as List<dynamic>?;
      if (places == null) return [];
      return places.map((p) {
        final name = p['name']?.toString() ?? 'Lugar';
        final lat = (p['lat'] is num)
            ? (p['lat'] as num).toDouble()
            : double.tryParse('${p['lat']}') ?? 0.0;
        final lng = (p['lng'] is num)
            ? (p['lng'] as num).toDouble()
            : double.tryParse('${p['lng']}') ?? 0.0;
        final address = p['address']?.toString() ?? '';
        final type = p['type']?.toString() ?? 'sitio';
        return PlaceEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}-$name',
          name: name,
          address: address,
          latitude: lat,
          longitude: lng,
          placeType: type,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String _stripJsonSuffix(String respuesta) {
    const marker = 'JSON_PLACES:';
    final idx = respuesta.lastIndexOf(marker);
    if (idx == -1) return respuesta;
    return respuesta.substring(0, idx).trim();
  }

  /// Consulta Nominatim para obtener datos reales de contacto y dirección.
  Future<List<PlaceEntity>> _enrichPlacesWithRealData(
    List<PlaceEntity> basePlaces,
    double latitude,
    double longitude,
  ) async {
    // Restringir búsqueda a un recuadro alrededor de la posición del usuario
    const radiusKm = 25.0; // foco local
    final deltaLat = radiusKm / 111.0;
    final deltaLon =
        radiusKm /
        (111.0 * math.cos(latitude * math.pi / 180.0)).abs().clamp(
          0.0001,
          1000.0,
        );
    final minLat = latitude - deltaLat;
    final maxLat = latitude + deltaLat;
    final minLon = longitude - deltaLon;
    final maxLon = longitude + deltaLon;

    final List<PlaceEntity> enriched = [];
    for (final p in basePlaces) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q='
          '${Uri.encodeQueryComponent(p.name)}'
          '&format=json&limit=1&extratags=1&addressdetails=1'
          '&countrycodes=co'
          '&viewbox=$minLon,$minLat,$maxLon,$maxLat&bounded=1',
        );
        final response = await http.get(
          uri,
          headers: {
            'User-Agent': 'WanderlyApp/1.0 (+https://wanderly.example)',
            'Accept': 'application/json',
            'Accept-Language': 'es',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data =
              json.decode(response.body) as List<dynamic>;
          if (data.isNotEmpty) {
            final item = data.first as Map<String, dynamic>;
            final Map<String, dynamic> extratags =
                (item['extratags'] as Map<String, dynamic>?) ?? {};
            final String? phone =
                (extratags['phone'] ?? extratags['contact:phone'])?.toString();
            final String? website =
                (extratags['website'] ?? extratags['contact:website'])
                    ?.toString();
            final String? instagram = extratags['contact:instagram']
                ?.toString();
            final String? facebook = extratags['contact:facebook']?.toString();
            final String address =
                item['display_name']?.toString() ?? p.address;
            final double? lat = double.tryParse(item['lat']?.toString() ?? '');
            final double? lon = double.tryParse(item['lon']?.toString() ?? '');
            // Asegurar proximidad: descartar si está demasiado lejos
            final double finalLat = lat ?? p.latitude;
            final double finalLon = lon ?? p.longitude;
            final double dist = _distanceKm(
              latitude,
              longitude,
              finalLat,
              finalLon,
            );
            if (dist > 35) {
              // Fuera del radio permitido: conservar original sin cambios
              enriched.add(p);
              continue;
            }
            enriched.add(
              PlaceEntity(
                id: p.id,
                name: p.name,
                address: address,
                latitude: finalLat,
                longitude: finalLon,
                placeType: p.placeType,
                rating: p.rating,
                fotoUrl: p.fotoUrl,
                phone: phone,
                website: website,
                instagram: instagram,
                facebook: facebook,
              ),
            );
          } else {
            enriched.add(p);
          }
        } else {
          enriched.add(p);
        }
      } catch (_) {
        enriched.add(p);
      }
    }
    return enriched;
  }

  // Filtro final: quedarse con lugares cercanos y con dirección en Colombia.
  List<PlaceEntity> _filterPlacesByProximity(
    List<PlaceEntity> places,
    double latitude,
    double longitude,
  ) {
    return places.where((p) {
      final dist = _distanceKm(latitude, longitude, p.latitude, p.longitude);
      final isNear = dist <= 50; // más permisivo, alineado al prompt
      return isNear;
    }).toList();
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // radio de la Tierra en km
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  Future<void> _onGuardarLugarFavorito(
    SaveFavoritePlaceEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.saveFavoritePlace(event.place);
      // Podrías emitir un estado de éxito aquí
    } catch (e) {
      emit(ChatError('Error al guardar lugar favorito: $e'));
    }
  }
}
