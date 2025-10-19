import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';

class MensajeChatModel {
  final String id;
  final String contenido;
  final bool esUsuario;
  final DateTime timestamp;
  final String? tipoLugar;

  MensajeChatModel({
    required this.id,
    required this.contenido,
    required this.esUsuario,
    required this.timestamp,
    this.tipoLugar,
  });

  factory MensajeChatModel.fromJson(Map<String, dynamic> json) {
    return MensajeChatModel(
      id: json['id'],
      contenido: json['contenido'],
      esUsuario: json['es_usuario'],
      timestamp: DateTime.parse(json['timestamp']),
      tipoLugar: json['tipo_lugar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenido': contenido,
      'es_usuario': esUsuario,
      'timestamp': timestamp.toIso8601String(),
      'tipo_lugar': tipoLugar,
    };
  }

  MensajeChatEntity toEntity() {
    return MensajeChatEntity(
      id: id,
      contenido: contenido,
      esUsuario: esUsuario,
      timestamp: timestamp,
      tipoLugar: tipoLugar,
    );
  }
}