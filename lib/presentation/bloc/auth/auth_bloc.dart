import 'package:bloc/bloc.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:wanderly/domain/entities/user_entity.dart';
import 'package:wanderly/domain/repositories/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

// Eventos
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      // Intentar iniciar sesión automáticamente tras registro exitoso
      try {
        await authRepository.signInWithEmail(
          email: event.email,
          password: event.password,
        );

        // Wait for Supabase session to become available via auth state stream
        UserEntity? usuarioStream;
        try {
          usuarioStream = await authRepository.currentUser
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 5), onTimeout: () => null);
        } catch (_) {
          usuarioStream = null;
        }

        // Fallback: poll getUsuarioActual briefly if stream is delayed
        UserEntity? user = usuarioStream;
        if (user == null) {
          for (int i = 0; i < 3 && user == null; i++) {
            await Future.delayed(const Duration(milliseconds: 300));
            user = await authRepository.getUsuarioActual();
          }
        }

        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(
            const AuthError('Failed to initialize user session after signup'),
          );
        }
      } catch (e) {
        // Si el proveedor requiere confirmación de email, mostrar message claro
        final msg = e.toString().replaceAll('Exception: ', '');
        emit(
          AuthError(msg.isEmpty ? 'Error signing in after registration' : msg),
        );
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );

      // Ensure the session is established and user is available
      UserEntity? user;
      try {
        user = await authRepository.currentUser
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
      } catch (_) {
        user = null;
      }

      user ??= await authRepository.getUsuarioActual();

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Failed to obtain user data'));
      }
    } catch (e) {
      // Limpiar el message de error removiendo 'Exception: '
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthError(errorMessage));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getUsuarioActual();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
