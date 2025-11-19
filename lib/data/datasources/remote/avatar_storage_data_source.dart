import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarStorageDataSource {
  final SupabaseClient _supabase;
  static const String bucket = 'avatars';

  AvatarStorageDataSource(this._supabase);

  /// Uploads avatar bytes for the given user id. Enforces a fixed path per user.
  /// Returns the public URL (if bucket is public) or signed URL if private.
  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/png',
  }) async {
    final path = '$userId/avatar.png';
    await _supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
        );
    // Política del bucket permite lectura pública; usar URL pública estable
    // y añadir un parámetro de versión para bustear caché del navegador.
    final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
    if (publicUrl.isEmpty) return null;
    final version = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?v=$version';
  }

  /// Deletes the user's avatar file.
  Future<void> deleteAvatar(String userId) async {
    final path = '$userId/avatar.png';
    await _supabase.storage.from(bucket).remove([path]);
  }
}