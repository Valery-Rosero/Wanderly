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
    return UsuarioModel(
      id: json['id'],
      email: json['email'],
      nombre: json['nombre'],
      fotoPerfil: json['foto_perfil'],
      createdAt: DateTime.parse(json['created_at']),
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
