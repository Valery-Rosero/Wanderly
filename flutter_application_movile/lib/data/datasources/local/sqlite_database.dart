import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'wanderly.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            remote_id TEXT,
            name TEXT NOT NULL,
            address TEXT,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            type TEXT,
            created_at INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE INDEX idx_fav_user_created ON favorites(user_id, created_at DESC);
        ''');

        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT UNIQUE NOT NULL,
            name TEXT,
            last_name TEXT,
            location_base TEXT,
            base_lat REAL,
            base_lon REAL,
            updated_at INTEGER NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE sync_outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT NOT NULL,
            op TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE chat_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            content TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            place_type TEXT,
            places_json TEXT
          );
        ''');

        await db.execute('''
          CREATE INDEX idx_chat_user_time ON chat_history(user_id, timestamp DESC);
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              content TEXT NOT NULL,
              is_user INTEGER NOT NULL,
              timestamp INTEGER NOT NULL,
              place_type TEXT,
              places_json TEXT
            );
          ''');
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_chat_user_time ON chat_history(user_id, timestamp DESC);
          ''');
        }
      },
    );
    return _db!;
  }

  static Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
