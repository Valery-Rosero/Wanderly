import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanderly/data/datasources/local/profile_local_data_source.dart';

class UsersRemoteDataSource {
  final SupabaseClient _supabase;
  UsersRemoteDataSource(this._supabase);

  Future<UserProfile?> obtenerprofile(String userId) async {
    final response = await _supabase
        .from('users')
        .select('id, first_name, last_name, home_base, base_lat, base_lon')
        .eq('id', userId)
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

  Future<void> actualizarprofile(UserProfile profile) async {
    await _supabase.from('users').upsert({
      'id': profile.userId,
      'first_name': profile.name,
      'last_name': profile.lastName,
      'home_base': profile.locationBase,
      'base_lat': profile.baseLat,
      'base_lon': profile.baseLon,
    });

    // Mantener sincronizado el nombre también en el metadata del usuario
    try {
      final f = profile.name?.trim();
      final l = profile.lastName?.trim();
      final combined =
          ((f != null && f.isNotEmpty) || (l != null && l.isNotEmpty))
          ? [
              f,
              l,
            ].where((s) => s != null && s!.isNotEmpty).map((s) => s!).join(' ')
          : (profile.name ?? '');

      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': combined}),
      );
    } catch (_) {
      // Silencioso: si falla metadata, al menos la tabla users queda actualizada
    }
  }
}
