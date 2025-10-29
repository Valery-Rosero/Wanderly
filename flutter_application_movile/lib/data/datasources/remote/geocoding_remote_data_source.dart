import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

/// Simple geocoding service using OpenStreetMap Nominatim API.
/// This works on Web and Mobile without API keys.
class GeocodingRemoteDataSource {
  /// Returns the first matching coordinate for the given address or place name.
  /// On failure, returns null.
  Future<latlng.LatLng?> geocodeAddress(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'WanderlyApp/1.0 (+https://wanderly.example)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;

    final item = data.first as Map<String, dynamic>;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return latlng.LatLng(lat, lon);
  }
}