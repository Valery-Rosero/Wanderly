import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://aieqxzhrnztfsruvnuah.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZXF4emhybnp0ZnNydXZudWFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyOTE5NDAsImV4cCI6MjA3ODg2Nzk0MH0.rxIV77Au9LuC93tzBT85udbDGwZ6EEBNohQysoUO36I';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
  }
}
