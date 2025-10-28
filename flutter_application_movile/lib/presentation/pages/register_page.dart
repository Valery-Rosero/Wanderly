import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_movile/core/theme/app_theme.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            Widget header = Container(
              height: isWide ? 220 : 200,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Crea tu cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );

            Widget formCard = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.message)),
                            );
                          } else if (state is AuthUnauthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Registro exitoso')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                LinearProgressIndicator(),
                              ],
                            );
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre completo',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                        SignUpRequested(
                                          email: emailController.text.trim(),
                                          password: passwordController.text.trim(),
                                          nombre: nombreController.text.trim(),
                                        ),
                                      );
                                },
                                child: const Text('Registrarse'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: header),
                  Expanded(child: formCard),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  formCard,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
