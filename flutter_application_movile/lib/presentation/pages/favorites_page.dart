import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_movile/data/datasources/remote/lugares_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/favorites_local_data_source.dart';
import 'package:flutter_application_movile/data/datasources/local/profile_local_data_source.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _cargando = true;
  List<LugarEntity> _favoritos = [];
  double? _baseLat, _baseLon;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) { setState(() => _cargando = false); return; }
    final userId = authState.usuario.id;
    final supabase = Supabase.instance.client;
    final rem = LugaresRemoteDataSource(supabase);
    final favLocal = kIsWeb ? null : await FavoritesLocalDataSource.create();
    final profileLocal = kIsWeb ? null : await ProfileLocalDataSource.create();

    try {
      // Base location
      if (profileLocal != null) {
        final p = await profileLocal.getProfile(userId);
        _baseLat = p?.baseLat; _baseLon = p?.baseLon;
      }

      // Favoritos locales si están
      if (favLocal != null) {
        _favoritos = await favLocal.getFavorites(userId);
      } else {
        // Web: leer de Supabase
        final data = await rem.obtenerLugaresFavoritos(userId);
        _favoritos = data.map((json) {
          final coord = _parseCoordenadas(json['coordenadas']);
          return LugarEntity(
            id: json['id'],
            nombre: json['nombre_lugar'],
            direccion: json['direccion'] ?? '',
            latitud: coord.$1,
            longitud: coord.$2,
            tipoLugar: json['tipo_lugar'] ?? '',
          );
        }).toList();
      }
    } catch (_) {}
    setState(() => _cargando = false);
  }

  (double, double) _parseCoordenadas(String coordenadas) {
    final regex = RegExp(r'POINT\(([-\d.]+) ([-\d.]+)\)');
    final match = regex.firstMatch(coordenadas);
    if (match != null) {
      return (double.parse(match.group(2)!), double.parse(match.group(1)!));
    }
    return (0.0, 0.0);
  }

  double? _distanceToBase(LugarEntity l) {
    if (_baseLat == null || _baseLon == null) return null;
    return Geolocator.distanceBetween(_baseLat!, _baseLon!, l.latitud, l.longitud);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _favoritos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final l = _favoritos[i];
                final d = _distanceToBase(l);
                final distStr = d != null ? '${(d/1000).toStringAsFixed(1)} km' : '--';
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    title: Text(l.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l.tipoLugar} • ${l.direccion}'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Distancia: $distStr', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Color(0xFF3B82F6)),
                          onPressed: () {
                            Navigator.pop(context, {'centerOn': {'lat': l.latitud, 'lon': l.longitud}});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is! AuthAuthenticated) return;
                            final userId = authState.usuario.id;
                            final supabase = Supabase.instance.client;
                            final rem = LugaresRemoteDataSource(supabase);
                            final favLocal = kIsWeb ? null : await FavoritesLocalDataSource.create();

                            try {
                              // Local delete first for responsiveness
                              if (favLocal != null) {
                                await favLocal.deleteFavorite(userId, l);
                              }
                              // Remote delete if we have a remote id
                              final idStr = l.id?.toString();
                              if (idStr != null && !(idStr.startsWith('local_'))){
                                await rem.eliminarLugarFavorito(usuarioId: userId, favoritoId: idStr);
                              } else if (favLocal != null && idStr != null) {
                                // Enqueue delete if remote id known but offline failure
                                await favLocal.enqueueSyncDeleteFavorite(userId, idStr);
                              }
                              setState(() {
                                _favoritos.removeAt(i);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favorito eliminado')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
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
}