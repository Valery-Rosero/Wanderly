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
import 'package:flutter_application_movile/core/theme/app_theme.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_application_movile/data/datasources/remote/geocoding_remote_data_source.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ChatBloc _chatBloc;
  Position? _ubicacionActual;
  latlng.LatLng? _ubicacionSeleccionada;
  bool _ubicacionCargando = false;
  String? _errorUbicacion;
  bool _chatInicializado = false;
  final TextEditingController _buscarCtrl = TextEditingController();
  bool _buscandoDireccion = false;
  String? _errorBusqueda;

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage initState llamado');
    _inicializarChat();
    // Solicitar ubicación al inicio para centrar el mapa y dar contexto.
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
        _ubicacionSeleccionada = latlng.LatLng(
          _ubicacionActual!.latitude,
          _ubicacionActual!.longitude,
        );
      }
      
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

  Future<void> _buscarDireccion() async {
    final query = _buscarCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _buscandoDireccion = true;
      _errorBusqueda = null;
    });

    try {
      final geocoder = GeocodingRemoteDataSource();
      final result = await geocoder.geocodeAddress(query);
      if (result == null) {
        setState(() {
          _errorBusqueda = 'No se encontró la dirección';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró la dirección')),
        );
      } else {
        setState(() {
          _ubicacionSeleccionada = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ubicación establecida: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorBusqueda = 'Error buscando dirección: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error buscando dirección: $e')),
      );
    } finally {
      setState(() {
        _buscandoDireccion = false;
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

    // Enviar mensaje usando ubicación seleccionada (manual o automática).
    final double lat = _ubicacionSeleccionada?.latitude ?? _ubicacionActual?.latitude ?? 0.0;
    final double lng = _ubicacionSeleccionada?.longitude ?? _ubicacionActual?.longitude ?? 0.0;
    _chatBloc.add(EnviarMensajeEvent(mensaje: mensaje, latitud: lat, longitud: lng));
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
          centerTitle: false,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wanderly', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Tu compañero de viaje', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
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
                tooltip: 'Permitir ubicación',
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_disabled, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorUbicacion!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _obtenerUbicacion,
                  child: const Text('Permitir ubicación'),
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
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(mensaje.id),
                        child: MensajeChatWidget(mensaje: mensaje),
                      ),
                    );
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
                            latitud: 0.0,
                            longitud: 0.0,
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
                      Icon(Icons.chat_bubble_rounded, size: 50, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Bienvenido a Wanderly!'),
                      SizedBox(height: 8),
                      Text('Pregúntame sobre lugares interesantes', 
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
        // Barra de búsqueda principal (ubicada sobre el mapa)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscarCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar dirección o lugar…',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _buscarDireccion(),
                  ),
                ),
                TextButton(
                  onPressed: _buscandoDireccion ? null : _buscarDireccion,
                  child: _buscandoDireccion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buscar'),
                ),
              ],
            ),
          ),
        ),
        // Mapa embebido con ubicación y lugares sugeridos
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final lugares = state is ChatLoaded ? state.lugares : <LugarEntity>[];
            return _buildMap(lugares);
          },
        ),
        if (_ubicacionSeleccionada != null || _ubicacionActual != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
                  ],
                ),
                child: Text(
                  'Lat: ${(_ubicacionSeleccionada?.latitude ?? _ubicacionActual!.latitude).toStringAsFixed(5)} · Lng: ${(_ubicacionSeleccionada?.longitude ?? _ubicacionActual!.longitude).toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ),
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return InputChatWidget(
              onEnviarMensaje: _enviarMensaje,
              estaCargando: state is ChatLoading,
              onUsarUbicacion: _obtenerUbicacion,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMap(List<LugarEntity> lugares) {
    if (_ubicacionActual == null && _ubicacionSeleccionada == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.map, color: Colors.grey),
              SizedBox(height: 8),
              Text('Activa tu ubicación para ver el mapa'),
            ],
          ),
        ),
      );
    }

    final center = _ubicacionSeleccionada ??
        latlng.LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude);
    final markers = <Marker>[
      // Marker del usuario
      Marker(
        point: center,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.white),
        ),
      ),
      // Markers de lugares sugeridos
      ...lugares.map((l) => Marker(
            point: latlng.LatLng(l.latitud, l.longitud),
            width: 34,
            height: 34,
            child: Tooltip(
              message: '${l.nombre}\n${l.direccion}',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.location_pin, color: Colors.redAccent),
              ),
            ),
          )),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                  onTap: (tapPos, point) {
                    setState(() {
                      _ubicacionSeleccionada = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.wanderly',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ],
          ),
        ),
      ),
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