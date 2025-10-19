import 'package:flutter_application_movile/domain/entities/lugar_entity.dart';

abstract class ChatRepository {
  Future<String> enviarMensaje({
    required String mensaje,
    required double latitud,
    required double longitud,
  });
  
  Future<void> guardarLugarFavorito(LugarEntity lugar);
  Future<List<LugarEntity>> obtenerLugaresFavoritos();
}