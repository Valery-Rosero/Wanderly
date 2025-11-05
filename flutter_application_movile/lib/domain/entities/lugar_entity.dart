class PlaceEntity {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String placeType;
  final double? rating;
  final String? fotoUrl;

  PlaceEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placeType,
    this.rating,
    this.fotoUrl,
  });
}