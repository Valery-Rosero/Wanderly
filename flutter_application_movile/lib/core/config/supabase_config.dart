import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://cmciptmywgloduwxqpqv.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtY2lwdG15d2dsb2R1d3hxcHF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NjM0MzgsImV4cCI6MjA3NzMzOTQzOH0.P-IocmTjynlsShm6OE1Zl9JJ-ecDruV-ljTVM3Di540';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
