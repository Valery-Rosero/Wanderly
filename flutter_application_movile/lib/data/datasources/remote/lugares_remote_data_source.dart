import 'package:supabase_flutter/supabase_flutter.dart';

class PlacesRemoteDataSource {
  final SupabaseClient _supabase;

  PlacesRemoteDataSource(this._supabase);

  Future<void> saveFavoritePlace({
    required String usuarioId,
    required String nombreLugar,
    required String address,
    required double latitude,
    required double longitude,
    required String placeType,
    String? notas,
  }) async {
    await _supabase.from('lugares_favoritos').insert({
      'usuario_id': usuarioId,
      'nombre_lugar': nombreLugar,
      'direccion': address,
      'coordenadas': 'POINT($longitude $latitude)',
      'tipo_lugar': placeType,
      'notas': notas,
    });
  }

  Future<List<Map<String, dynamic>>> getFavoritePlaces(String usuarioId) async {
    final response = await _supabase
        .from('lugares_favoritos')
        .select()
        .eq('usuario_id', usuarioId)
        .order('created_at', ascending: false);

    return response;
  }

  Future<void> eliminarLugarFavorito({
    required String usuarioId,
    required String favoritoId,
  }) async {
    await _supabase
        .from('lugares_favoritos')
        .delete()
        .eq('usuario_id', usuarioId)
        .eq('id', favoritoId);
  }
}