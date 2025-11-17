import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanderly/domain/entities/user_entity.dart';
import 'package:wanderly/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Error al crear usuario');
      }

      // Verificar si el user ya existe en la tabla
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        await _supabase.from('users').insert({
          'id': user.id,
          // Removed 'email' to avoid column-not-found error
          'first_name': name,
        });
      }
    } on AuthException catch (e) {
      // Specific auth error handling with clear, user-friendly messages
      final msg = e.message ?? '';
      if (msg.contains('User already registered') ||
          msg.contains('already registered')) {
        throw Exception('This email is already in use. Please log in instead.');
      } else if (msg.contains('Email not confirmed')) {
        throw Exception('Please confirm your email to complete registration.');
      } else if (msg.contains('Invalid email')) {
        throw Exception('Please enter a valid email address.');
      } else {
        throw Exception('Authentication error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verificar que la sesión se creó correctamente
      if (response.session == null) {
        throw Exception('No se pudo crear la sesión');
      }
    } on AuthException catch (e) {
      // Specific login error handling
      final msg = e.message ?? '';
      if (msg.contains('Invalid login credentials')) {
        throw Exception('Incorrect email or password.');
      } else if (msg.contains('Email not confirmed')) {
        throw Exception('Please confirm your email before logging in.');
      } else if (msg.contains('Invalid email')) {
        throw Exception('Please enter a valid email address.');
      } else {
        throw Exception('Authentication error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign-in error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Stream<UserEntity?> get currentUser {
    return _supabase.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      if (user != null) {
        return UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'] as String?,
          createdAt: DateTime.now(),
        );
      }
      return null;
    });
  }

  @override
  Future<UserEntity?> getUsuarioActual() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          // Build entity using row data + fallback to auth email
          return UserEntity(
            id: response['id'] as String? ?? user.id,
            email: user.email ?? '',
            name:
                response['first_name'] as String? ??
                (user.userMetadata?['full_name'] as String?),
            createdAt: DateTime.now(),
          );
        } else {
          return UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'] as String?,
            createdAt: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      print('Error en getUsuarioActual: $e');
      return null;
    }
  }
}
