import 'package:equatable/equatable.dart'; 
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/domain/repositories/chat_repository.dart';

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

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<SendMessageEvent>(_onEnviarMensaje);
    on<GuardarLugarFavoritoEvent>(_onGuardarLugarFavorito);
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
      // Intentar extraer places del sufijo JSON_PLACES
      _lugares = _parsePlacesFromResponse(respuesta);
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