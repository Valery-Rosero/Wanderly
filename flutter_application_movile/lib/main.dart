import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_application_movile/core/config/supabase_config.dart';
import 'package:flutter_application_movile/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_movile/presentation/pages/home_page.dart';
import 'package:flutter_application_movile/presentation/pages/login_page.dart';
import 'package:flutter_application_movile/presentation/pages/register_page.dart';
import 'package:flutter_application_movile/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase PRIMERO
  await SupabaseConfig.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final supabase.SupabaseClient supabaseClient = supabase.Supabase.instance.client;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepositoryImpl(supabaseClient),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepositoryImpl>(),
        )..add(CheckAuthStatus()),
        child: MaterialApp(
          title: 'Wanderly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const AuthWrapper(),
          routes: {
            '/home': (_) => const HomePage(),
            '/login': (_) => LoginPage(),
            '/register': (_) => const RegisterPage(),
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
//hala madrid
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('🔍 AuthWrapper - Estado actual: ${state.runtimeType}');
        
        if (state is AuthAuthenticated) {
          print('✅ Navegando a HomePage - Usuario: ${state.usuario.email}');
          return const HomePage();
        } else if (state is AuthUnauthenticated) {
          print('🔐 Navegando a LoginPage');
          return LoginPage();
        } else if (state is AuthError) {
          print('❌ Error de autenticación: ${state.message}');
          // Mostrar login pero con snackbar de error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return LoginPage();
        }
        
        // Estado inicial o loading
        print('⏳ Mostrando loading...');
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verificando autenticación...'),
              ],
            ),
          ),
        );
      },
    );
  }
}