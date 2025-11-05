import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_movile/data/datasources/local/sqlite_database.dart';

class UserProfile {
  final String userId;
  final String? name;
  final String? apellido;
  final String? ubicacionBase;
  final double? baseLat;
  final double? baseLon;

  UserProfile({
    required this.userId,
    this.name,
    this.apellido,
    this.ubicacionBase,
    this.baseLat,
    this.baseLon,
  });
}

class ProfileLocalDataSource {
  final Database _db;
  ProfileLocalDataSource(this._db);

  static Future<ProfileLocalDataSource> create() async {
    final db = await AppDatabase.instance();
    return ProfileLocalDataSource(db);
  }

  Future<UserProfile?> getProfile(String userId) async {
    final rows = await _db.query('user_profile', where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserProfile(
      userId: r['user_id'] as String,
      name: r['nombre'] as String?,
      apellido: r['apellido'] as String?,
      ubicacionBase: r['ubicacion_base'] as String?,
      baseLat: (r['base_lat'] as num?)?.toDouble(),
      baseLon: (r['base_lon'] as num?)?.toDouble(),
    );
  }

  Future<void> upsertProfile(UserProfile profile, {bool markSynced = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert(
      'user_profile',
      {
        'user_id': profile.userId,
        'nombre': profile.name,
        'apellido': profile.apellido,
        'ubicacion_base': profile.ubicacionBase,
        'base_lat': profile.baseLat,
        'base_lon': profile.baseLon,
        'updated_at': now,
        'synced': markSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}