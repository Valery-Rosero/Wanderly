class LugarEntity {
  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final String tipoLugar;
  final double? rating;
  final String? fotoUrl;

  LugarEntity({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.tipoLugar,
    this.rating,
    this.fotoUrl,
  });
}