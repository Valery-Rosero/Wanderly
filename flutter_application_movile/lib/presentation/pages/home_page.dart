import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'package:flutter_application_movile/core/theme/app_theme.dart';
import 'package:flutter_application_movile/data/datasources/local/location_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/gemini_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/geocoding_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/lugares_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/routing_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/favorites_local_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/chat_history_local_data_source.dart';
import 'package:flutter_application_movile/data/repositories/chat_repository_impl.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_movile/presentation/bloc/chat/chat_bloc.dart';
import 'package:flutter_application_movile/presentation/widgets/input_chat_widget.dart';
import 'package:flutter_application_movile/presentation/widgets/mensaje_chat_widget.dart';
import 'package:flutter_application_movile/presentation/pages/profile_page.dart';
import 'package:flutter_application_movile/presentation/pages/favorites_page.dart';
import 'package:flutter_application_movile/presentation/pages/map_full_page.dart';

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
  bool _mapVisible = true;
  final MapController _mapController = MapController();
  final RoutingRemoteDataSource _routing = RoutingRemoteDataSource();
  List<latlng.LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage initState llamado');
    _inicializarChat();
    // Solicitar ubicación al inicio para centrar el map y dar contexto.
    _obtenerUbicacion();
  }

  Future<void> _inicializarChat() async {
    try {
      print('🔧 Inicializando ChatBloc...');
      final authState = context.read<AuthBloc>().state;
      
      if (authState is AuthAuthenticated) {
        print('✅ Usuario autenticado: ${authState.user.id}');
        // En web no inicializamos SQLite
        final favoritesLocal = kIsWeb ? null : await FavoritesLocalDataSource.create();
        final historyLocal = kIsWeb ? null : await ChatHistoryLocalDataSource.create();
        
        _chatBloc = ChatBloc(
          chatRepository: ChatRepositoryImpl(
            geminiDataSource: GeminiRemoteDataSource(),
            lugaresDataSource: PlacesRemoteDataSource(Supabase.instance.client),
            favoritesLocal: favoritesLocal,
            historyLocal: historyLocal,
            usuarioId: authState.user.id,
          ),
          usuarioId: authState.user.id,
        );
        
        print('🎉 ChatBloc inicializado exitosamente');
        setState(() {
          _chatInicializado = true;
        });
        // Cargar historial de chat (móvil)
        if (!kIsWeb) {
          _chatBloc.add(LoadChatHistoryEvent(usuarioId: authState.user.id));
        }
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
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorUbicacion = 'Los servicios de ubicación están deshabilitados. Por favor, actívalos para una mejor experiencia.';
          _ubicacionCargando = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorUbicacion = 'Para brindarte sugerencias personalizadas, necesitamos acceso a tu ubicación. Puedes habilitarlo en la configuración.';
            _ubicacionCargando = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorUbicacion = 'Los permisos de ubicación están permanentemente denegados. Por favor, habilítalos en la configuración del navegador para obtener sugerencias personalizadas.';
          _ubicacionCargando = false;
        });
        return;
      }

      // Get current position with highest accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );

      // Verify accuracy and retry if needed
      if (position.accuracy > 50) {
        print('🎯 Precisión inicial: ${position.accuracy}m - Intentando mejorar...');
        
        // Try to get a more accurate position
        try {
          Position betterPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 10),
          );
          
          if (betterPosition.accuracy < position.accuracy) {
            position = betterPosition;
            print('✅ Precisión mejorada: ${position.accuracy}m');
          }
        } catch (e) {
          print('⚠️ No se pudo mejorar la precisión, usando posición inicial');
        }
      }

      setState(() {
        _ubicacionActual = position;
        _ubicacionCargando = false;
      });

      // Auto-center map on user location with high precision
      final userLocation = latlng.LatLng(position.latitude, position.longitude);
      _mapController.move(userLocation, 16.0); // Higher zoom for precision
      
      // Start continuous location tracking for better accuracy
      _startLocationTracking();
      
      // Generate initial location-based suggestions
      _generateLocationBasedSuggestions(userLocation);

      print('📍 Ubicación obtenida con precisión: ${position.accuracy}m');
      print('📍 Coordenadas: ${position.latitude}, ${position.longitude}');

    } catch (e) {
      setState(() {
        _errorUbicacion = 'No pudimos obtener tu ubicación en este momento. Puedes seleccionar manualmente un lugar en el mapa.';
        _ubicacionCargando = false;
      });
    }
  }

  StreamSubscription<Position>? _locationSubscription;

  void _startLocationTracking() {
    // Cancel any existing subscription
    _locationSubscription?.cancel();
    
    // Start continuous location tracking with high accuracy
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(seconds: 10),
      ),
    ).listen(
      (Position position) {
        // Only update if the new position is significantly more accurate or different
        if (_ubicacionActual == null || 
            position.accuracy < _ubicacionActual!.accuracy ||
            Geolocator.distanceBetween(
              _ubicacionActual!.latitude, 
              _ubicacionActual!.longitude,
              position.latitude, 
              position.longitude
            ) > 10) {
          
          setState(() {
            _ubicacionActual = position;
          });
          
          print('🔄 Ubicación actualizada - Precisión: ${position.accuracy}m');
        }
      },
      onError: (error) {
        print('❌ Error en seguimiento de ubicación: $error');
      },
    );
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

  void _enviarMensaje(String message) {
    print('📤 Intentando enviar mensaje: $message');
    
    if (!_chatInicializado) {
      print('❌ ChatBloc no inicializado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat no inicializado. Intenta recargar la página.')),
      );
      return;
    }

    // Enviar message usando ubicación seleccionada (manual o automática).
    final double lat = _ubicacionSeleccionada?.latitude ?? _ubicacionActual?.latitude ?? 0.0;
    final double lng = _ubicacionSeleccionada?.longitude ?? _ubicacionActual?.longitude ?? 0.0;
    _chatBloc.add(SendMessageEvent(message: message, latitude: lat, longitude: lng));
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
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Perfil',
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              tooltip: 'Favoritos',
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
                if (result is Map && result['centerOn'] is Map) {
                  final c = result['centerOn'] as Map;
                  final lat = (c['lat'] as num).toDouble();
                  final lon = (c['lon'] as num).toDouble();
                  _mapController.move(latlng.LatLng(lat, lon), 16.0);
                }
              },
            ),
            IconButton(
              icon: Icon(_mapVisible ? Icons.visibility : Icons.visibility_off),
              tooltip: _mapVisible ? 'Ocultar mapa' : 'Mostrar mapa',
              onPressed: () {
                setState(() {
                  _mapVisible = !_mapVisible;
                });
              },
            ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF3F4F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
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
                print('💬 Mensajes en chat: ${state.messages.length}');
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: false,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(message.id),
                        child: MensajeChatWidget(
                          message: message,
                          onPlaceTap: _centerOnPlace,
                          places: state.places,
                        ),
                      ),
                    );
                  },
                );
              }
              else if (state is ChatError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _chatBloc.add(SendMessageEvent(
                            message: 'Hola',
                            latitude: 0.0,
                            longitude: 0.0,
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
        // Barra de búsqueda y mapa (se muestra sólo si _mapVisible)
        if (_mapVisible)
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final places = state is ChatLoaded ? state.places : <PlaceEntity>[];
              return _buildMap(places);
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
    ),
  );
  }

  Widget _buildMap(List<PlaceEntity> places) {
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
      // Enhanced user location marker
      Marker(
        point: center,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      
      // Enhanced markers for chatbot recommended places
      ...places.asMap().entries.map((entry) {
        final index = entry.key;
        final place = entry.value;
        
        return Marker(
          point: latlng.LatLng(place.latitude, place.longitude),
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () => _centerOnPlace(place),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.purple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _getPlaceIcon(place.placeType),
                    color: Colors.white,
                    size: 20,
                  ),
                  // Recommendation number badge
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (tapPos, point) {
                    setState(() {
                      _ubicacionSeleccionada = point;
                    });
                  },
                  onMapEvent: (MapEvent mapEvent) {
                    if (mapEvent is MapEventMoveEnd) {
                      // Trigger dynamic suggestions when map stops moving
                      _onMapMoveEnd(mapEvent.camera.center);
                    }
                  },
                ),
                children: [
                  // Enhanced OpenStreetMap tile layer with better quality and caching
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.wanderly.app',
                    maxZoom: 19,
                    minZoom: 3,
                    // Better error handling and fallback
                    errorTileCallback: (tile, error, stackTrace) {
                      print('🗺️ Error loading tile: $error');
                    },
                    // Better caching and performance
                    maxNativeZoom: 19,
                    zoomOffset: 0,
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Botón para abrir el mapa en otra página cuando haya lugares
              if (places.isNotEmpty)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapFullPage(
                            center: center,
                            places: places,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir mapa'),
                  ),
                ),
              // Search bar overlayed on top of the map (prevents page overflow)
              Positioned(
                left: 12,
                right: 12, // full width with symmetric padding
                top: 12,
                child: SafeArea(
                  top: true,
                  minimum: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              hintText: 'Buscar dirección o lugar…',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
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
              ),
              // Zoom controls
              Positioned(
                right: 16,
                top: 72, // place below the search bar
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              onTap: () {
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom + 1,
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.add, size: 20),
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              onTap: () {
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom - 1,
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.remove, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Center on user location button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _centerOnUserLocation,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.my_location, size: 20, color: Colors.blue),
                          ),
                        ),
                      ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_routePoints.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                _routePoints = [];
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.clear, size: 20),
                            ),
                          ),
                        ),
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
    // Cancel location subscription to prevent memory leaks
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _centerOnUserLocation() {
    if (_ubicacionActual != null) {
      final userLocation = latlng.LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude);
      _mapController.move(userLocation, 15.0);
      setState(() {
        _ubicacionSeleccionada = userLocation;
      });
    }
  }

  void _onMapMoveEnd(latlng.LatLng center) {
    // Trigger dynamic suggestions based on the new map center
    _generateLocationBasedSuggestions(center);
  }

  void _generateLocationBasedSuggestions(latlng.LatLng location) {
    // This method will generate contextual suggestions based on the location
    // For now, we'll add a simple implementation that can be enhanced later
    final lat = location.latitude;
    final lng = location.longitude;
    
    // For now, we'll just print the suggestion to console
    // This can be enhanced later with a proper event system for automatic suggestions
    print('🗺️ Área explorable: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}');
    print('💡 Sugerencia: El usuario puede preguntar sobre restaurantes, atracciones, hoteles en esta área');
  }

  // Helper method to get appropriate icon for place type
  IconData _getPlaceIcon(String? tipo) {
    if (tipo == null) return Icons.place;
    
    switch (tipo.toLowerCase()) {
      case 'restaurant':
      case 'restaurante':
      case 'food':
      case 'comida':
        return Icons.restaurant;
      case 'hotel':
      case 'lodging':
      case 'hospedaje':
        return Icons.hotel;
      case 'tourist_attraction':
      case 'attraction':
      case 'atraccion':
      case 'turismo':
        return Icons.camera_alt;
      case 'shopping_mall':
      case 'store':
      case 'tienda':
      case 'compras':
        return Icons.shopping_bag;
      case 'hospital':
      case 'health':
      case 'salud':
        return Icons.local_hospital;
      case 'gas_station':
      case 'gasolina':
        return Icons.local_gas_station;
      case 'bank':
      case 'atm':
      case 'banco':
        return Icons.account_balance;
      case 'park':
      case 'parque':
        return Icons.nature;
      case 'museum':
      case 'museo':
        return Icons.museum;
      case 'church':
      case 'iglesia':
        return Icons.church;
      default:
        return Icons.place;
    }
  }

  // Method to smoothly center map on a specific place
  void _centerOnPlace(PlaceEntity place) async {
    final placeLocation = latlng.LatLng(place.latitude, place.longitude);
    
    // Smooth animation to center on the place
    _mapController.move(placeLocation, 17.0);
    
    // Update selected location
    setState(() {
      _ubicacionSeleccionada = placeLocation;
    });

    // Draw route from current location if available
    try {
      if (_ubicacionActual != null) {
        final points = await _routing.getRoute(
          startLat: _ubicacionActual!.latitude,
          startLon: _ubicacionActual!.longitude,
          endLat: place.latitude,
          endLon: place.longitude,
        );
        setState(() {
          _routePoints = points
              .map((p) => latlng.LatLng(p[0], p[1]))
              .toList();
        });
      }
    } catch (e) {
      print('⚠️ Error fetching route: $e');
    }
    
    // Show a snackbar with place information
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getPlaceIcon(place.placeType),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (place.address.isNotEmpty)
                    Text(
                      place.address,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    
    print('🎯 Centrado en: ${place.name} (${place.latitude}, ${place.longitude})');
  }

}