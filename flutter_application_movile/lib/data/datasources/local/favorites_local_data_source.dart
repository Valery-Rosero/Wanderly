import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application_movile/data/datasources/local/sqlite_database.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

class FavoritesLocalDataSource {
  final Database _db;

  FavoritesLocalDataSource(this._db);

  static Future<FavoritesLocalDataSource> create() async {
    final db = await AppDatabase.instance();
    return FavoritesLocalDataSource(db);
  }

  Future<int> saveFavorite(String userId, PlaceEntity place) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _db.insert(
      'favorites',
      {
        'user_id': userId,
        'remote_id': place.id,
        'nombre': place.name,
        'direccion': place.address,
        'lat': place.latitude,
        'lon': place.longitude,
        'tipo': place.placeType,
        'created_at': now,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<PlaceEntity>> getFavorites(String userId) async {
    final rows = await _db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => PlaceEntity(
          id: (r['remote_id'] as String?) ?? 'local_${r['id']}',
          name: r['nombre'] as String,
          address: (r['direccion'] as String?) ?? '',
          latitude: (r['lat'] as num).toDouble(),
          longitude: (r['lon'] as num).toDouble(),
          placeType: (r['tipo'] as String?) ?? '',
        )).toList();
  }

  Future<void> markFavoriteSynced(int localId, String remoteId) async {
    await _db.update(
      'favorites',
      {'synced': 1, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> enqueueSyncFavorite(String userId, PlaceEntity place) async {
    final payload = jsonEncode({
      'usuario_id': userId,
      'nombre_lugar': place.name,
      'direccion': place.address,
      'latitud': place.latitude,
      'longitud': place.longitude,
      'tipo_lugar': place.placeType,
      'notas': 'Guardado desde chat',
    });
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert('sync_outbox', {
      'entity': 'favorite',
      'op': 'create',
      'payload': payload,
      'created_at': now,
      'status': 'pending',
      'retry_count': 0,
    });
  }

  Future<int> deleteFavorite(String userId, PlaceEntity place) async {
    // Try delete by remote_id if available, otherwise match by fields
    if (place.id != null && !(place.id!.startsWith('local_'))) {
      return await _db.delete(
        'favorites',
        where: 'user_id = ? AND remote_id = ?',
        whereArgs: [userId, place.id],
      );
    }
    return await _db.delete(
      'favorites',
      where: 'user_id = ? AND nombre = ? AND lat = ? AND lon = ?',
      whereArgs: [userId, place.name, place.latitude, place.longitude],
    );
  }

  Future<void> enqueueSyncDeleteFavorite(String userId, String remoteId) async {
    final payload = jsonEncode({
      'usuario_id': userId,
      'favorito_id': remoteId,
    });
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert('sync_outbox', {
      'entity': 'favorite',
      'op': 'delete',
      'payload': payload,
      'created_at': now,
      'status': 'pending',
      'retry_count': 0,
    });
  }
  Future<List<Map<String, dynamic>>> getPendingOutbox() async {
    return _db.query('sync_outbox', where: 'status = ?', whereArgs: ['pending']);
  }

  Future<void> markOutboxItem(String id, {required String status}) async {
    await _db.update('sync_outbox', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }
}