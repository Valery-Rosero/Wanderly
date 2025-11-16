import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_movile/data/datasources/local/favorites_local_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/profile_local_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/places_remote_data_source.dart';
import 'package:flutter_application_movile/domain/entities/place_entity.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _loading = true;
  List<PlaceEntity> _favorites = [];
  double? _baseLat, _baseLon;

  @override
  void initState() {
    super.initState();
    _toLoad();
  }

  Future<void> _toLoad() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    final userId = authState.user.id;
    final supabase = Supabase.instance.client;
    final rem = PlacesRemoteDataSource(supabase);
    final favLocal = kIsWeb ? null : await FavoritesLocalDataSource.create();
    final profileLocal = kIsWeb ? null : await ProfileLocalDataSource.create();

    try {
      // Base location
      if (profileLocal != null) {
        final p = await profileLocal.getProfile(userId);
        _baseLat = p?.baseLat;
        _baseLon = p?.baseLon;
      }

      if (favLocal != null) {
        _favorites = await favLocal.getFavorites(userId);
      } else {
        // Web: leer de Supabase con claves en inglés y fallback a español
        final data = await rem.getFavoritePlaces(userId);
        _favorites = data.map((json) {
          final coordsStr =
              (json['coordinates'] ?? json['coordenadas'] ?? '') as String;
          final coord = _parseCoordenadas(coordsStr);
          return PlaceEntity(
            id: json['id'].toString(),
            name: (json['place_name'] ?? json['nombre_lugar'] ?? '') as String,
            address: (json['address'] ?? json['direccion'] ?? '') as String,
            latitude: coord.$1,
            longitude: coord.$2,
            placeType:
                (json['place_type'] ?? json['tipo_lugar'] ?? '') as String,
          );
        }).toList();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  (double, double) _parseCoordenadas(String coordenadas) {
    final regex = RegExp(r'POINT\(([-\d.]+) ([-\d.]+)\)');
    final match = regex.firstMatch(coordenadas);
    if (match != null) {
      return (double.parse(match.group(2)!), double.parse(match.group(1)!));
    }
    return (0.0, 0.0);
  }

  double? _distanceToBase(PlaceEntity l) {
    if (_baseLat == null || _baseLon == null) return null;
    return Geolocator.distanceBetween(
      _baseLat!,
      _baseLon!,
      l.latitude,
      l.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final l = _favorites[i];
                final d = _distanceToBase(l);
                final distStr = d != null
                    ? '${(d / 1000).toStringAsFixed(1)} km'
                    : '--';
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white),
                    ),
                    title: Text(
                      l.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l.placeType} • ${l.address}'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Distancia: $distStr',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Color(0xFF3B82F6)),
                          onPressed: () async {
                            await _openDirections(_favorites[i]);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is! AuthAuthenticated) return;
                            final userId = authState.user.id;
                            final supabase = Supabase.instance.client;
                            final rem = PlacesRemoteDataSource(supabase);
                            final favLocal = kIsWeb
                                ? null
                                : await FavoritesLocalDataSource.create();

                            try {
                              // Local delete first for responsiveness
                              if (favLocal != null) {
                                await favLocal.deleteFavorite(userId, l);
                              }
                              // Remote delete only if the ID looks like a Supabase row id (numeric)
                              final idStr = l.id.toString();
                              final isNumericId = RegExp(
                                r'^\d+$',
                              ).hasMatch(idStr);
                              if (isNumericId) {
                                await rem.deleteFavoritePlace(
                                  userId: userId,
                                  favoriteId: idStr,
                                );
                              }
                              setState(() {
                                _favorites.removeAt(i);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Favorito eliminado'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al eliminar: $e'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openDirections(PlaceEntity l) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa los servicios de ubicación')),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos de ubicación denegados')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final origin = '${pos.latitude},${pos.longitude}';
      final dest = '${l.latitude},${l.longitude}';
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving',
      );

      // Abre en una pestaña nueva (web) o en la app de mapas (móvil)
      // Usa url_launcher (ya incluido en el proyecto)
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir las indicaciones: $e')),
      );
    }
  }
}
