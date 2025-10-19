import 'package:equatable/equatable.dart'; 
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

  const ChatLoaded(this.mensajes);

  @override
  List<Object> get props => [mensajes];
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
    emit(ChatLoaded(List.from(_mensajes)));

    try {
      // Obtener respuesta de Gemini
      final respuesta = await _chatRepository.enviarMensaje(
        mensaje: event.mensaje,
        latitud: event.latitud,
        longitud: event.longitud,
      );

      // Agregar respuesta del chatbot
      _mensajes.add(MensajeChatEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contenido: respuesta,
        esUsuario: false,
        timestamp: DateTime.now(),
      ));
      emit(ChatLoaded(List.from(_mensajes)));
    } catch (e) {
      _mensajes.add(MensajeChatEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contenido: 'Error: $e',
        esUsuario: false,
        timestamp: DateTime.now(),
      ));
      emit(ChatLoaded(List.from(_mensajes)));
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