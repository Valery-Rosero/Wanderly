import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://kdivncbqhizpaqqdibts.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkaXZuY2JxaGl6cGFxcWRpYnRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4MDM0NzUsImV4cCI6MjA3NjM3OTQ3NX0.NF6TXa5FizWxJNWhuXSW1E3C_zdRUtW-z49aJjiYVh0';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}