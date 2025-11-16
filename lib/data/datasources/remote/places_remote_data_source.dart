import 'package:supabase_flutter/supabase_flutter.dart';

class PlacesRemoteDataSource {
  final SupabaseClient _supabase;

  PlacesRemoteDataSource(this._supabase);

  Future<String> saveFavoritePlace({
    required String userId,
    required String placeName,
    required String address,
    required double latitude,
    required double longitude,
    required String placeType,
    String? notes,
  }) async {
    final inserted = await _supabase
        .from('favorite_places')
        .insert({
          'user_id': userId,
          'place_name': placeName,
          'address': address,
          'coordinates': 'POINT($longitude $latitude)',
          'place_type': placeType,
          'notes': notes,
        })
        .select('id')
        .single();
    return inserted['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getFavoritePlaces(String userId) async {
    final response = await _supabase
        .from('favorite_places')
        .select('id, user_id, place_name, address, coordinates, place_type, notes, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> deleteFavoritePlace({
    required String userId,
    required String favoriteId,
  }) async {
    await _supabase
        .from('favorite_places')
        .delete()
        .eq('user_id', userId)
        .eq('id', favoriteId);
  }
}