import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';  
import 'package:flutter_application_movile/domain/entities/usuario_entity.dart';
import 'package:flutter_application_movile/domain/repositories/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UsuarioEntity usuario;

  const AuthAuthenticated(this.usuario);

  @override
  List<Object> get props => [usuario];
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
  final String nombre;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.nombre,
  });

  @override
  List<Object> get props => [email, password, nombre];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

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
        nombre: event.nombre,
      );
      // Tras el registro exitoso, permanecemos en estado no autenticado
      // para que el usuario vuelva al Login y pueda iniciar sesión.
      emit(AuthUnauthenticated());
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
      
      // Pequeña pausa para asegurar que la sesión se establezca
      await Future.delayed(const Duration(milliseconds: 500));
      
      final usuario = await authRepository.getUsuarioActual();
      if (usuario != null) {
        emit(AuthAuthenticated(usuario));
      } else {
        emit(const AuthError('No se pudieron obtener los datos del usuario'));
      }
    } catch (e) {
      // Limpiar el mensaje de error removiendo 'Exception: '
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
      final usuario = await authRepository.getUsuarioActual();
      if (usuario != null) {
        emit(AuthAuthenticated(usuario));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}