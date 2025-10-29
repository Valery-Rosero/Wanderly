import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_movile/data/datasources/local/location_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/gemini_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/lugares_remote_data_source.dart';
import 'package:flutter_application_movile/data/repositories/chat_repository_impl.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_movile/presentation/bloc/chat/chat_bloc.dart';
import 'package:flutter_application_movile/presentation/widgets/input_chat_widget.dart';
import 'package:flutter_application_movile/presentation/widgets/mensaje_chat_widget.dart';
import 'package:flutter_application_movile/presentation/pages/edit_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ChatBloc _chatBloc;
  Position? _ubicacionActual;
  bool _ubicacionCargando = false;
  String? _errorUbicacion;
  bool _chatInicializado = false;

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage initState llamado');
    _inicializarChat();
    _obtenerUbicacion();
  }

  void _inicializarChat() {
    try {
      print('🔧 Inicializando ChatBloc...');
      final authState = context.read<AuthBloc>().state;
      
      if (authState is AuthAuthenticated) {
        print('✅ Usuario autenticado: ${authState.usuario.id}');
        
        _chatBloc = ChatBloc(
          chatRepository: ChatRepositoryImpl(
            geminiDataSource: GeminiRemoteDataSource(),
            lugaresDataSource: LugaresRemoteDataSource(Supabase.instance.client),
            usuarioId: authState.usuario.id,
          ),
        );
        
        print('🎉 ChatBloc inicializado exitosamente');
        setState(() {
          _chatInicializado = true;
        });
      } else {
        print('❌ Usuario no autenticado en _inicializarChat');
      }
    } catch (e) {
      print('💥 Error inicializando ChatBloc: $e');
    }
  }

  Future<void> _obtenerUbicacion() async {
    setState(() {
      _ubicacionCargando = true;
      _errorUbicacion = null;
    });

    try {
      print('📍 Solicitando ubicación...');
      final locationDataSource = LocationDataSource();
      
      // ✅ USAR EL MÉTODO CORRECTO: getCurrentLocation()
      _ubicacionActual = await locationDataSource.getCurrentLocation();
      
      if (_ubicacionActual != null) {
        print('📍 Ubicación obtenida: ${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}');
      } else {
        print('📍 Ubicación es null');
      }
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      setState(() {
        _errorUbicacion = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de ubicación: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _obtenerUbicacion,
          ),
        ),
      );
    } finally {
      setState(() {
        _ubicacionCargando = false;
      });
    }
  }

  void _enviarMensaje(String mensaje) {
    print('📤 Intentando enviar mensaje: $mensaje');
    
    if (!_chatInicializado) {
      print('❌ ChatBloc no inicializado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat no inicializado. Intenta recargar la página.')),
      );
      return;
    }

    if (_ubicacionCargando) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obteniendo ubicación, por favor espera...')),
      );
      return;
    }

    if (_ubicacionActual != null) {
      print('📍 Enviando mensaje con ubicación: ${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}');
      _chatBloc.add(EnviarMensajeEvent(
        mensaje: mensaje,
        latitud: _ubicacionActual!.latitude,
        longitud: _ubicacionActual!.longitude,
      ));
    } else {
      print('❌ Ubicación no disponible para enviar mensaje');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorUbicacion ?? 'Ubicación no disponible'),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _obtenerUbicacion,
          ),
        ),
      );
    }
  }

  void _cerrarSesion() {
    context.read<AuthBloc>().add(SignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 HomePage build llamado - Chat inicializado: $_chatInicializado');
    
    if (!_chatInicializado) {
      return _buildLoadingScreen();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _chatBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Travel Chatbot'),
          actions: [
            if (_ubicacionCargando)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_ubicacionActual != null)
              IconButton(
                icon: const Icon(Icons.location_on, color: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ubicación: ${_ubicacionActual!.latitude.toStringAsFixed(4)}, '
                        '${_ubicacionActual!.longitude.toStringAsFixed(4)}',
                      ),
                    ),
                  );
                },
                tooltip: 'Ubicación obtenida',
              )
            else
              IconButton(
                icon: const Icon(Icons.location_off, color: Colors.red),
                onPressed: _obtenerUbicacion,
                tooltip: 'Reintentar ubicación',
              ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
              tooltip: 'Editar perfil',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _cerrarSesion,
              tooltip: 'Cerrar Sesión',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Chatbot')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Inicializando chatbot...'),
            if (_ubicacionCargando) ...[
              const SizedBox(height: 10),
              const Text('Obteniendo ubicación...', style: TextStyle(fontSize: 12)),
            ],
            if (_errorUbicacion != null) ...[
              const SizedBox(height: 10),
              Text('Error: $_errorUbicacion', style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _obtenerUbicacion,
                child: const Text('Reintentar Ubicación'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('🔄 Recargando HomePage...');
                setState(() {
                  _chatInicializado = false;
                });
                _inicializarChat();
              },
              child: const Text('Reintentar Chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_errorUbicacion != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange[100],
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorUbicacion!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _obtenerUbicacion,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        Expanded(
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              print('💬 ChatBloc State: ${state.runtimeType}');
              
              if (state is ChatLoaded) {
                print('💬 Mensajes en chat: ${state.mensajes.length}');
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: false,
                  itemCount: state.mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = state.mensajes[index];
                    return MensajeChatWidget(mensaje: mensaje);
                  },
                );
              } else if (state is ChatError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _chatBloc.add(EnviarMensajeEvent(
                            mensaje: 'Hola',
                            latitud: _ubicacionActual?.latitude ?? 4.6097,
                            longitud: _ubicacionActual?.longitude ?? -74.0817,
                          ));
                        },
                        child: const Text('Reintentar Chat'),
                      ),
                    ],
                  ),
                );
              } else if (state is ChatInitial) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 50, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Bienvenido al Travel Chatbot!'),
                      SizedBox(height: 8),
                      Text('Pregúntame sobre lugares cercanos', 
                           style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando chat...'),
                  ],
                ),
              );
            },
          ),
        ),
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return InputChatWidget(
              onEnviarMensaje: _enviarMensaje,
              estaCargando: state is ChatLoading,
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('🏠 HomePage dispose llamado');
    if (_chatInicializado) {
      _chatBloc.close();
    }
    super.dispose();
  }
}