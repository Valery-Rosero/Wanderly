import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_movile/data/datasources/local/profile_local_data_source.dart';

class UsuariosRemoteDataSource {
  final SupabaseClient _supabase;
  UsuariosRemoteDataSource(this._supabase);

  Future<UserProfile?> obtenerPerfil(String usuarioId) async {
    final response = await _supabase
        .from('usuarios')
        .select('id, nombre, apellido, ubicacion_base, base_lat, base_lon')
        .eq('id', usuarioId)
        .maybeSingle();
    if (response == null) return null;
    return UserProfile(
      userId: response['id'] as String,
      nombre: response['nombre'] as String?,
      apellido: response['apellido'] as String?,
      ubicacionBase: response['ubicacion_base'] as String?,
      baseLat: (response['base_lat'] as num?)?.toDouble(),
      baseLon: (response['base_lon'] as num?)?.toDouble(),
    );
  }

  Future<void> actualizarPerfil(UserProfile perfil) async {
    await _supabase.from('usuarios').upsert({
      'id': perfil.userId,
      'nombre': perfil.nombre,
      'ubicacion_base': perfil.ubicacionBase,
      'base_lat': perfil.baseLat,
      'base_lon': perfil.baseLon,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}