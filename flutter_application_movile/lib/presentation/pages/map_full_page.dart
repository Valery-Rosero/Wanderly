import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_application_movile/core/theme/app_theme.dart';
import 'package:flutter_application_movile/domain/entities/place_entity.dart';
import 'package:flutter_application_movile/data/datasources/remote/routing_remote_data_source.dart';

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
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
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
        ],
      ),
    );
  }
}
