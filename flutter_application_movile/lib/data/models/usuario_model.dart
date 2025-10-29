import 'package:flutter_application_movile/domain/entities/usuario_entity.dart';

class UsuarioModel {
  final String id;
  final String email;
  final String? nombre;
  final String? fotoPerfil;
  final DateTime createdAt;

  UsuarioModel({
    required this.id,
    required this.email,
    this.nombre,
    this.fotoPerfil,
    required this.createdAt,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final nombre = json['nombre'] as String?;
    final fotoPerfil = json['foto_perfil'] as String?;
    final createdRaw = json['created_at'];
    final createdAt = (createdRaw is String && createdRaw.isNotEmpty)
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    return UsuarioModel(
      id: id,
      email: email,
      nombre: nombre,
      fotoPerfil: fotoPerfil,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'foto_perfil': fotoPerfil,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UsuarioEntity toEntity() {
    return UsuarioEntity(
      id: id,
      email: email,
      nombre: nombre,
      fotoPerfil: fotoPerfil,
      createdAt: createdAt,
    );
  }
}
