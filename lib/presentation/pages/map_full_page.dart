import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:wanderly/core/theme/app_theme.dart';
import 'package:wanderly/domain/entities/place_entity.dart';
import 'package:wanderly/data/datasources/remote/routing_remote_data_source.dart';

class MapFullPage extends StatefulWidget {
  final latlng.LatLng center;
  final List<PlaceEntity> places;
  final latlng.LatLng? userLocation;
  final PlaceEntity? selectedPlace;

  const MapFullPage({
    super.key,
    required this.center,
    required this.places,
    this.userLocation,
    this.selectedPlace,
  });

  @override
  State<MapFullPage> createState() => _MapFullPageState();
}

class _MapFullPageState extends State<MapFullPage> {
  final mapController = MapController();
  final _routing = RoutingRemoteDataSource();
  List<latlng.LatLng> _routePoints = [];
  bool _loadingRoute = false;
  RoutingMode _mode = RoutingMode.driving;

  @override
  void initState() {
    super.initState();
    _maybeFetchRoute();
  }

  Future<void> _maybeFetchRoute() async {
    final user = widget.userLocation;
    final dest = widget.selectedPlace;
    if (user != null && dest != null) {
      setState(() => _loadingRoute = true);
      try {
        final coords = await _routing.getRoute(
          startLat: user.latitude,
          startLon: user.longitude,
          endLat: dest.latitude,
          endLon: dest.longitude,
          mode: _mode,
        );
        setState(() {
          _routePoints = coords.map((c) => latlng.LatLng(c[0], c[1])).toList();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo calcular la ruta: $e')),
        );
      } finally {
        if (mounted) setState(() => _loadingRoute = false);
      }
    }
  }

  Future<void> _recalculateRoute() async {
    final user = widget.userLocation;
    final dest = widget.selectedPlace;
    if (user == null || dest == null) return;
    setState(() => _loadingRoute = true);
    try {
      final coords = await _routing.getRoute(
        startLat: user.latitude,
        startLon: user.longitude,
        endLat: dest.latitude,
        endLon: dest.longitude,
        mode: _mode,
      );
      setState(() {
        _routePoints = coords.map((c) => latlng.LatLng(c[0], c[1])).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo calcular la ruta: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: widget.center,
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
          child: const Icon(Icons.place, color: Colors.white, size: 24),
        ),
      ),
      ...widget.places.map(
        (place) => Marker(
          point: latlng.LatLng(place.latitude, place.longitude),
          width: 45,
          height: 45,
          child: Tooltip(
            message: place.name,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.purple.shade600],
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
              child: const Icon(Icons.place, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Centrar en selección',
            onPressed: () {
              mapController.move(widget.center, 16.0);
            },
          ),
          PopupMenuButton<RoutingMode>(
            tooltip: 'Modo de ruta',
            initialValue: _mode,
            onSelected: (mode) {
              setState(() => _mode = mode);
              _recalculateRoute();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: RoutingMode.driving,
                child: Row(
                  children: const [
                    Icon(Icons.directions_car),
                    SizedBox(width: 8),
                    Text('Coche'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: RoutingMode.walking,
                child: Row(
                  children: const [
                    Icon(Icons.directions_walk),
                    SizedBox(width: 8),
                    Text('A pie'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.alt_route),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.wanderly.app',
                maxZoom: 19,
                minZoom: 3,
                maxNativeZoom: 19,
                zoomOffset: 0,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: _mode == RoutingMode.driving
                          ? Colors.deepPurple
                          : Colors.green,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          // Selector flotante visible en móvil
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              top: true,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: PopupMenuButton<RoutingMode>(
                  initialValue: _mode,
                  tooltip: 'Modo de ruta',
                  onSelected: (mode) {
                    setState(() => _mode = mode);
                    _recalculateRoute();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: RoutingMode.driving,
                      child: Row(
                        children: [
                          Icon(Icons.directions_car),
                          SizedBox(width: 8),
                          Text('Auto'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: RoutingMode.walking,
                      child: Row(
                        children: [
                          Icon(Icons.directions_walk),
                          SizedBox(width: 8),
                          Text('Caminando'),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _mode == RoutingMode.driving
                              ? Icons.directions_car
                              : Icons.directions_walk,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _mode == RoutingMode.driving ? 'Auto' : 'Caminando',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loadingRoute)
            const Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_routePoints.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                tooltip: 'Limpiar ruta',
                onPressed: () {
                  setState(() => _routePoints = []);
                },
                child: const Icon(Icons.clear),
              ),
            ),
          // Botón flotante para alternar rápidamente el modo de ruta
          Positioned(
            right: 12,
            bottom: 72,
            child: FloatingActionButton.small(
              tooltip: 'Cambiar modo de ruta',
              onPressed: _cycleMode,
              child: Icon(
                _mode == RoutingMode.driving
                    ? Icons.directions_car
                    : Icons.directions_walk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Alternar modo con botón flotante
  void _cycleMode() {
    setState(() {
      switch (_mode) {
        case RoutingMode.driving:
          _mode = RoutingMode.walking;
          break;
        case RoutingMode.walking:
        case RoutingMode.cycling:
          _mode = RoutingMode.driving;
          break;
      }
    });
    _recalculateRoute();
  }
}
