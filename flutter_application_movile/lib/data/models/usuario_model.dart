import 'package:flutter_application_movile/domain/entities/usuario_entity.dart';

class UsuarioModel {
  final String id;
  final String email;
  final String? name;
  final String? fotoPerfil;
  final DateTime createdAt;

  UsuarioModel({
    required this.id,
    required this.email,
    this.name,
    this.fotoPerfil,
    required this.createdAt,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final name = json['nombre'] as String?;
    final fotoPerfil = json['foto_perfil'] as String?;
    final createdRaw = json['created_at'];
    final createdAt = (createdRaw is String && createdRaw.isNotEmpty)
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    return UsuarioModel(
      id: id,
      email: email,
      name: name,
      fotoPerfil: fotoPerfil,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': name,
      'foto_perfil': fotoPerfil,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      fotoPerfil: fotoPerfil,
      createdAt: createdAt,
    );
  }
}
