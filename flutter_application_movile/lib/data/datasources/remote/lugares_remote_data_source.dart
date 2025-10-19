import 'package:supabase_flutter/supabase_flutter.dart';

class LugaresRemoteDataSource {
  final SupabaseClient _supabase;

  LugaresRemoteDataSource(this._supabase);

  Future<void> guardarLugarFavorito({
    required String usuarioId,
    required String nombreLugar,
    required String direccion,
    required double latitud,
    required double longitud,
    required String tipoLugar,
    String? notas,
  }) async {
    await _supabase.from('lugares_favoritos').insert({
      'usuario_id': usuarioId,
      'nombre_lugar': nombreLugar,
      'direccion': direccion,
      'coordenadas': 'POINT($longitud $latitud)',
      'tipo_lugar': tipoLugar,
      'notas': notas,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerLugaresFavoritos(String usuarioId) async {
    final response = await _supabase
        .from('lugares_favoritos')
        .select()
        .eq('usuario_id', usuarioId)
        .order('created_at', ascending: false);

    return response;
  }
}