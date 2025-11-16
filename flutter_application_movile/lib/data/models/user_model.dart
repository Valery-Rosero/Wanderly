import 'package:flutter_application_movile/domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? profilePicture;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.profilePicture,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final name = json['first_name'] as String?;
    final profilePicture = json['profile_picture'] as String?;
    final createdRaw = json['created_at'];
    final createdAt = (createdRaw is String && createdRaw.isNotEmpty)
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    return UserModel(
      id: id,
      email: email,
      name: name,
      profilePicture: profilePicture,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': name,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      profilePicture: profilePicture,
      createdAt: createdAt,
    );
  }
}
