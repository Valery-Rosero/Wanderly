import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception('Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    }
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
  }
}
