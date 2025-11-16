import 'package:flutter_application_movile/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<UserEntity?> get currentUser;

  Future<UserEntity?> getUsuarioActual();
}
