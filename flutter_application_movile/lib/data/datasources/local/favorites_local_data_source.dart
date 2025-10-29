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

  Future<int> saveFavorite(String userId, LugarEntity lugar) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _db.insert(
      'favorites',
      {
        'user_id': userId,
        'remote_id': lugar.id,
        'nombre': lugar.nombre,
        'direccion': lugar.direccion,
        'lat': lugar.latitud,
        'lon': lugar.longitud,
        'tipo': lugar.tipoLugar,
        'created_at': now,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<LugarEntity>> getFavorites(String userId) async {
    final rows = await _db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => LugarEntity(
          id: (r['remote_id'] as String?) ?? 'local_${r['id']}',
          nombre: r['nombre'] as String,
          direccion: (r['direccion'] as String?) ?? '',
          latitud: (r['lat'] as num).toDouble(),
          longitud: (r['lon'] as num).toDouble(),
          tipoLugar: (r['tipo'] as String?) ?? '',
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

  Future<void> enqueueSyncFavorite(String userId, LugarEntity lugar) async {
    final payload = jsonEncode({
      'usuario_id': userId,
      'nombre_lugar': lugar.nombre,
      'direccion': lugar.direccion,
      'latitud': lugar.latitud,
      'longitud': lugar.longitud,
      'tipo_lugar': lugar.tipoLugar,
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

  Future<int> deleteFavorite(String userId, LugarEntity lugar) async {
    // Try delete by remote_id if available, otherwise match by fields
    if (lugar.id != null && !(lugar.id!.startsWith('local_'))) {
      return await _db.delete(
        'favorites',
        where: 'user_id = ? AND remote_id = ?',
        whereArgs: [userId, lugar.id],
      );
    }
    return await _db.delete(
      'favorites',
      where: 'user_id = ? AND nombre = ? AND lat = ? AND lon = ?',
      whereArgs: [userId, lugar.nombre, lugar.latitud, lugar.longitud],
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