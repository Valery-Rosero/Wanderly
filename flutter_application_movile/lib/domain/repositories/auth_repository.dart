import 'package:flutter_application_movile/domain/entities/usuario_entity.dart';

abstract class AuthRepository {
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nombre,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<UsuarioEntity?> get currentUser;

  Future<UsuarioEntity?> getUsuarioActual();
}
