import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_movile/data/datasources/local/sqlite_database.dart';
import 'package:flutter_application_movile/domain/entities/mensaje_chat_entity.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

class ChatHistoryLocalDataSource {
  final Database _db;

  ChatHistoryLocalDataSource(this._db);

  static Future<ChatHistoryLocalDataSource> create() async {
    final db = await AppDatabase.instance();
    // Ensure table exists (older installs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        contenido TEXT NOT NULL,
        es_usuario INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        place_type TEXT,
        places_json TEXT
      );
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_chat_user_time ON chat_history(user_id, timestamp DESC);
    ''');
    return ChatHistoryLocalDataSource(db);
  }

  Future<void> addMessage(String userId, ChatMessageEntity message, {List<PlaceEntity>? places}) async {
    await _db.insert(
      'chat_history',
      {
        'user_id': userId,
        'contenido': message.contenido,
        'es_usuario': message.esUsuario ? 1 : 0,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'place_type': message.placeType,
        'places_json': places == null
            ? null
            : jsonEncode(places.map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'address': p.address,
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                  'placeType': p.placeType,
                }).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<ChatMessageEntity>> getMessages(String userId, {int limit = 200}) async {
    final rows = await _db.query(
      'chat_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map((r) => ChatMessageEntity(
          id: (r['id']?.toString()) ?? DateTime.now().millisecondsSinceEpoch.toString(),
          contenido: r['contenido'] as String,
          esUsuario: (r['es_usuario'] as int) == 1,
          timestamp: DateTime.fromMillisecondsSinceEpoch((r['timestamp'] as int)),
          placeType: r['place_type'] as String?,
        )).toList();
  }

  Future<void> clearHistory(String userId) async {
    await _db.delete('chat_history', where: 'user_id = ?', whereArgs: [userId]);
  }
}