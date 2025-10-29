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
  final List<MensajeChatEntity> mensajes;
  final List<LugarEntity> lugares;

  const ChatLoaded(this.mensajes, {this.lugares = const []});

  @override
  List<Object> get props => [mensajes, lugares];
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

class EnviarMensajeEvent extends ChatEvent {
  final String mensaje;
  final double latitud;
  final double longitud;

  const EnviarMensajeEvent({
    required this.mensaje,
    required this.latitud,
    required this.longitud,
  });

  @override
  List<Object> get props => [mensaje, latitud, longitud];
}

class GuardarLugarFavoritoEvent extends ChatEvent {
  final LugarEntity lugar;

  const GuardarLugarFavoritoEvent(this.lugar);

  @override
  List<Object> get props => [lugar];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final List<MensajeChatEntity> _mensajes = [];
  List<LugarEntity> _lugares = [];

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<EnviarMensajeEvent>(_onEnviarMensaje);
    on<GuardarLugarFavoritoEvent>(_onGuardarLugarFavorito);
  }

  Future<void> _onEnviarMensaje(
    EnviarMensajeEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Agregar mensaje del usuario
    _mensajes.add(MensajeChatEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contenido: event.mensaje,
      esUsuario: true,
      timestamp: DateTime.now(),
    ));
    emit(ChatLoaded(List.from(_mensajes), lugares: List.from(_lugares)));

    try {
      // Obtener respuesta de Gemini
      final respuesta = await _chatRepository.enviarMensaje(
        mensaje: event.mensaje,
        latitud: event.latitud,
        longitud: event.longitud,
      );

      // Agregar respuesta del chatbot (texto)
      _mensajes.add(MensajeChatEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contenido: respuesta,
        esUsuario: false,
        timestamp: DateTime.now(),
      ));
      // Intentar extraer lugares del sufijo JSON_PLACES
      _lugares = _parsePlacesFromResponse(respuesta);
      emit(ChatLoaded(List.from(_mensajes), lugares: List.from(_lugares)));
    } catch (e) {
      _mensajes.add(MensajeChatEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contenido: 'Error: $e',
        esUsuario: false,
        timestamp: DateTime.now(),
      ));
      emit(ChatLoaded(List.from(_mensajes), lugares: List.from(_lugares)));
  }
  }

  List<LugarEntity> _parsePlacesFromResponse(String respuesta) {
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
        return LugarEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}-${name}',
          nombre: name,
          direccion: address,
          latitud: lat,
          longitud: lng,
          tipoLugar: type,
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
      await _chatRepository.guardarLugarFavorito(event.lugar);
      // Podrías emitir un estado de éxito aquí
    } catch (e) {
      emit(ChatError('Error al guardar lugar favorito: $e'));
    }
  }
}