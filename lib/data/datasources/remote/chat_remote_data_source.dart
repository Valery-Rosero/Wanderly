import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanderly/domain/entities/place_entity.dart';

class ChatRemoteDataSource {
  final SupabaseClient _client;

  ChatRemoteDataSource(this._client);

  Future<String> createSession({
    required String userId,
    required String title,
  }) async {
    try {
      print('🟦 [Supabase] createSession user=$userId title="$title"');
      final res = await _client
          .from('chat_sessions')
          .insert({'user_id': userId, 'title': title})
          .select('id')
          .single();
      final id = res['id'].toString();
      print('✅ [Supabase] session created id=$id');
      return id;
    } catch (e) {
      print('❌ [Supabase] createSession error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listSessions(String userId) async {
    try {
      print('🟦 [Supabase] listSessions user=$userId');
      final data = await _client
          .from('chat_sessions')
          .select('id, title, created_at, last_message_at, is_archived')
          .eq('user_id', userId)
          .order('last_message_at', ascending: false)
          .order('created_at', ascending: false);
      final list = (data as List).cast<Map<String, dynamic>>();
      print('✅ [Supabase] sessions fetched count=${list.length}');
      return list;
    } catch (e) {
      print('❌ [Supabase] listSessions error: $e');
      rethrow;
    }
  }

  Future<void> addMessage({
    required String sessionId,
    required bool isUser,
    required String content,
    String? placeType,
    List<PlaceEntity>? places,
  }) async {
    try {
      final placesJson = places == null
          ? null
          : places.map((p) {
              return {
                'id': p.id,
                'name': p.name,
                'address': p.address,
                'lat': p.latitude,
                'lng': p.longitude,
                'type': p.placeType,
              };
            }).toList();

      print(
        '🟦 [Supabase] addMessage session=$sessionId role=${isUser ? 'user' : 'assistant'}',
      );
      await _client.from('chat_messages').insert({
        'session_id': sessionId,
        'role': isUser ? 'user' : 'assistant',
        'content': content,
        'place_type': placeType,
        'places_json': placesJson,
      });

      await _client
          .from('chat_sessions')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
      print('✅ [Supabase] message inserted and session updated');
    } catch (e) {
      print('❌ [Supabase] addMessage error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required String sessionId,
    int limit = 200,
  }) async {
    try {
      print('🟦 [Supabase] getMessages session=$sessionId limit=$limit');
      final data = await _client
          .from('chat_messages')
          .select('id, role, content, place_type, created_at')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true)
          .limit(limit);
      final list = (data as List).cast<Map<String, dynamic>>();
      print('✅ [Supabase] messages fetched count=${list.length}');
      return list;
    } catch (e) {
      print('❌ [Supabase] getMessages error: $e');
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      print('🟦 [Supabase] deleteSession id=$sessionId');
      // Primero borrar mensajes asociados (por si no hay cascada)
      await _client
          .from('chat_messages')
          .delete()
          .eq('session_id', sessionId);
      // Luego borrar la sesión
      await _client.from('chat_sessions').delete().eq('id', sessionId);
      print('✅ [Supabase] session deleted id=$sessionId');
    } catch (e) {
      print('❌ [Supabase] deleteSession error: $e');
      rethrow;
    }
  }

  Future<void> deleteAllSessions(String userId) async {
    try {
      print('🟦 [Supabase] deleteAllSessions user=$userId');
      final sessions = await listSessions(userId);
      final ids = sessions.map((s) => s['id']).toList();
      if (ids.isNotEmpty) {
        // Borrar las sesiones por id (con cascada a mensajes)
        await _client
            .from('chat_sessions')
            .delete()
            .inFilter('id', ids);
      }
      print('✅ [Supabase] all sessions deleted for user=$userId');
    } catch (e) {
      print('❌ [Supabase] deleteAllSessions error: $e');
      rethrow;
    }
  }
}
