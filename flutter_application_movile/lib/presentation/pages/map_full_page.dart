import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_application_movile/core/theme/app_theme.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

class MapFullPage extends StatelessWidget {
  final latlng.LatLng center;
  final List<PlaceEntity> places;

  const MapFullPage({super.key, required this.center, required this.places});

  @override
  Widget build(BuildContext context) {
    final mapController = MapController();

    final markers = <Marker>[
      // Centro del mapa (ubicación seleccionada/actual)
      Marker(
        point: center,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 24),
        ),
      ),
      // Lugares sugeridos
      ...places.map((place) => Marker(
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
          )),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Centrar en selección',
            onPressed: () {
              mapController.move(center, 16.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.wanderly.app',
                maxZoom: 19,
                minZoom: 3,
                maxNativeZoom: 19,
                zoomOffset: 0,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ],
      ),
    );
  }
}