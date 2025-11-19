import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanderly/data/datasources/local/profile_local_data_source.dart';

class UsersRemoteDataSource {
  final SupabaseClient _supabase;
  UsersRemoteDataSource(this._supabase);

  Future<UserProfile?> obtenerPerfil(String usuarioId) async {
    final response = await _supabase
        .from('users')
        .select('id, first_name, last_name, home_base, base_lat, base_lon')
        .eq('id', usuarioId)
        .maybeSingle();
    if (response == null) return null;
    return UserProfile(
      userId: response['id'] as String,
      name: response['first_name'] as String?,
      lastName: response['last_name'] as String?,
      locationBase: response['home_base'] as String?,
      baseLat: (response['base_lat'] as num?)?.toDouble(),
      baseLon: (response['base_lon'] as num?)?.toDouble(),
    );
  }

  Future<void> actualizarPerfil(UserProfile perfil) async {
    await _supabase.from('users').upsert({
      'id': perfil.userId,
      'first_name': perfil.name,
      'last_name': perfil.lastName,
      'home_base': perfil.locationBase,
      'base_lat': perfil.baseLat,
      'base_lon': perfil.baseLon,
    });

    // Mantener sincronizado el nombre también en el metadata del usuario
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'full_name': perfil.name,
        }),
      );
    } catch (_) {
      // Silencioso: si falla metadata, al menos la tabla users queda actualizada
    }
  }
}
