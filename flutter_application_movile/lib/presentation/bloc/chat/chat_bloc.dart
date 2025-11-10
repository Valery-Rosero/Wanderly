import 'package:equatable/equatable.dart'; 
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/domain/repositories/chat_repository.dart';
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
  final String usuarioId;
  final int limit;

  const LoadChatHistoryEvent({required this.usuarioId, this.limit = 200});

  @override
  List<Object> get props => [usuarioId, limit];
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

class GuardarLugarFavoritoEvent extends ChatEvent {
  final PlaceEntity place;

  const GuardarLugarFavoritoEvent(this.place);

  @override
  List<Object> get props => [place];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final List<ChatMessageEntity> _mensajes = [];
  List<PlaceEntity> _lugares = [];
  final String _usuarioId;

  ChatBloc({required ChatRepository chatRepository, required String usuarioId})
      : _chatRepository = chatRepository,
        _usuarioId = usuarioId,
        super(ChatInitial()) {
    on<SendMessageEvent>(_onEnviarMensaje);
    on<GuardarLugarFavoritoEvent>(_onGuardarLugarFavorito);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
  }

  Future<void> _onEnviarMensaje(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Agregar message del user
    _mensajes.add(ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contenido: event.message,
      esUsuario: true,
      timestamp: DateTime.now(),
    ));
    // Persistir historial local en móvil
    if (!kIsWeb) {
      await _chatRepository.saveChatMessage(
        userId: _usuarioId,
        contenido: event.message,
        esUsuario: true,
        timestamp: DateTime.now(),
      );
    }
    emit(ChatLoaded(List.from(_mensajes), places: List.from(_lugares)));

    try {
      // Obtener respuesta de Gemini
      final respuesta = await _chatRepository.sendMessage(
        message: event.message,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      // Agregar respuesta del chatbot (texto)
      _mensajes.add(ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contenido: respuesta,
        esUsuario: false,
        timestamp: DateTime.now(),
      ));
      if (!kIsWeb) {
        await _chatRepository.saveChatMessage(
          userId: _usuarioId,
          contenido: respuesta,
          esUsuario: false,
          timestamp: DateTime.now(),
        );
      }
      // Intentar extraer places del sufijo JSON_PLACES
      _lugares = _parsePlacesFromResponse(respuesta);
      // Enriquecer lugares con datos reales (teléfono, web, dirección) usando Nominatim
      if (_lugares.isNotEmpty) {
        _lugares = await _enrichPlacesWithRealData(_lugares, event.latitude, event.longitude);
      }
      emit(ChatLoaded(List.from(_mensajes), places: List.from(_lugares)));
    } catch (e) {
      _mensajes.add(ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contenido: 'Error: $e',
        esUsuario: false,
        timestamp: DateTime.now(),
      ));
      emit(ChatLoaded(List.from(_mensajes), places: List.from(_lugares)));
  }
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final history = await _chatRepository.getChatHistory(
        userId: event.usuarioId,
        limit: event.limit,
      );
      _mensajes
        ..clear()
        ..addAll(history);
      emit(ChatLoaded(List.from(_mensajes), places: List.from(_lugares)));
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
        final lat = (p['lat'] is num) ? (p['lat'] as num).toDouble() : double.tryParse('${p['lat']}') ?? 0.0;
        final lng = (p['lng'] is num) ? (p['lng'] as num).toDouble() : double.tryParse('${p['lng']}') ?? 0.0;
        final address = p['address']?.toString() ?? '';
        final type = p['type']?.toString() ?? 'sitio';
        return PlaceEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}-${name}',
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

  /// Consulta Nominatim para obtener datos reales de contacto y dirección.
  Future<List<PlaceEntity>> _enrichPlacesWithRealData(
    List<PlaceEntity> basePlaces,
    double latitude,
    double longitude,
  ) async {
    final List<PlaceEntity> enriched = [];
    for (final p in basePlaces) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q='
          '${Uri.encodeQueryComponent(p.name)}'
          '&format=json&limit=1&extratags=1',
        );
        final response = await http.get(
          uri,
          headers: {
            'User-Agent': 'WanderlyApp/1.0 (+https://wanderly.example)',
            'Accept': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body) as List<dynamic>;
          if (data.isNotEmpty) {
            final item = data.first as Map<String, dynamic>;
            final Map<String, dynamic> extratags =
                (item['extratags'] as Map<String, dynamic>?) ?? {};
            final String? phone = (extratags['phone'] ?? extratags['contact:phone'])?.toString();
            final String? website = (extratags['website'] ?? extratags['contact:website'])?.toString();
            final String? instagram = extratags['contact:instagram']?.toString();
            final String? facebook = extratags['contact:facebook']?.toString();
            final String address = item['display_name']?.toString() ?? p.address;
            final double? lat = double.tryParse(item['lat']?.toString() ?? '');
            final double? lon = double.tryParse(item['lon']?.toString() ?? '');
            enriched.add(PlaceEntity(
              id: p.id,
              name: p.name,
              address: address,
              latitude: lat ?? p.latitude,
              longitude: lon ?? p.longitude,
              placeType: p.placeType,
              rating: p.rating,
              fotoUrl: p.fotoUrl,
              phone: phone,
              website: website,
              instagram: instagram,
              facebook: facebook,
            ));
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

  Future<void> _onGuardarLugarFavorito(
    GuardarLugarFavoritoEvent event,
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