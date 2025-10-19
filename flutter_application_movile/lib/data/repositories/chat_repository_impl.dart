import 'package:flutter_application_movile/data/datasources/remote/gemini_remote_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/lugares_remote_data_source.dart';
import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';
import 'package:flutter_application_movile/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiRemoteDataSource _geminiDataSource;
  final LugaresRemoteDataSource _lugaresDataSource;
  final String _usuarioId;

  ChatRepositoryImpl({
    required GeminiRemoteDataSource geminiDataSource,
    required LugaresRemoteDataSource lugaresDataSource,
    required String usuarioId,
  })  : _geminiDataSource = geminiDataSource,
        _lugaresDataSource = lugaresDataSource,
        _usuarioId = usuarioId;

  @override
  Future<String> enviarMensaje({
    required String mensaje,
    required double latitud,
    required double longitud,
  }) async {
    return await _geminiDataSource.obtenerRecomendacion(
      mensaje: mensaje,
      latitud: latitud,
      longitud: longitud,
    );
  }

  @override
  Future<void> guardarLugarFavorito(LugarEntity lugar) async {
    await _lugaresDataSource.guardarLugarFavorito(
      usuarioId: _usuarioId,
      nombreLugar: lugar.nombre,
      direccion: lugar.direccion,
      latitud: lugar.latitud,
      longitud: lugar.longitud,
      tipoLugar: lugar.tipoLugar,
      notas: 'Guardado desde chat',
    );
  }

  @override
  Future<List<LugarEntity>> obtenerLugaresFavoritos() async {
    final data = await _lugaresDataSource.obtenerLugaresFavoritos(_usuarioId);
    return data.map((json) {
      final coordenadas = _parseCoordenadas(json['coordenadas']);
      return LugarEntity(
        id: json['id'],
        nombre: json['nombre_lugar'],
        direccion: json['direccion'],
        latitud: coordenadas.$1,
        longitud: coordenadas.$2,
        tipoLugar: json['tipo_lugar'],
      );
    }).toList();
  }


  (double, double) _parseCoordenadas(String coordenadas) {
    // Parsear "POINT(lng lat)" de PostGIS
    final regex = RegExp(r'POINT\(([-\d.]+) ([-\d.]+)\)');
    final match = regex.firstMatch(coordenadas);
    if (match != null) {
      return (double.parse(match.group(2)!), double.parse(match.group(1)!));
    }
    return (0.0, 0.0);
  }
}