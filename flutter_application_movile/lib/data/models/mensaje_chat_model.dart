import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';

class ChatMessageModel {
  final String id;
  final String contenido;
  final bool esUsuario;
  final DateTime timestamp;
  final String? placeType;

  ChatMessageModel({
    required this.id,
    required this.contenido,
    required this.esUsuario,
    required this.timestamp,
    this.placeType,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      contenido: json['contenido'],
      esUsuario: json['es_usuario'],
      timestamp: DateTime.parse(json['timestamp']),
      placeType: json['tipo_lugar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenido': contenido,
      'es_usuario': esUsuario,
      'timestamp': timestamp.toIso8601String(),
      'tipo_lugar': placeType,
    };
  }

  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      contenido: contenido,
      esUsuario: esUsuario,
      timestamp: timestamp,
      placeType: placeType,
    );
  }
}