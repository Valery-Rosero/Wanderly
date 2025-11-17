import 'package:sqflite/sqflite.dart';
import 'package:wanderly/data/datasources/local/sqlite_database.dart';

class UserProfile {
  final String userId;
  final String? name;
  final String? lastName;
  final String? locationBase;
  final double? baseLat;
  final double? baseLon;

  UserProfile({
    required this.userId,
    this.name,
    this.lastName,
    this.locationBase,
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
    final rows = await _db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserProfile(
      userId: r['user_id'] as String,
      name: r['name'] as String?,
      lastName: r['last_name'] as String?,
      locationBase: r['location_base'] as String?,
      baseLat: (r['base_lat'] as num?)?.toDouble(),
      baseLon: (r['base_lon'] as num?)?.toDouble(),
    );
  }

  Future<void> upsertProfile(
    UserProfile profile, {
    bool markSynced = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert('user_profile', {
      'user_id': profile.userId,
      'name': profile.name,
      'last_name': profile.lastName,
      'location_base': profile.locationBase,
      'base_lat': profile.baseLat,
      'base_lon': profile.baseLon,
      'updated_at': now,
      'synced': markSynced ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
