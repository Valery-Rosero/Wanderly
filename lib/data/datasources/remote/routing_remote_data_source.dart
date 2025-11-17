import 'dart:convert';
import 'package:http/http.dart' as http;

enum RoutingMode { driving, walking, cycling }

class RoutingRemoteDataSource {
  Future<List<List<double>>> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    RoutingMode mode = RoutingMode.driving,
  }) async {
    final profile = switch (mode) {
      RoutingMode.driving => 'driving',
      RoutingMode.walking => 'walking',
      RoutingMode.cycling => 'cycling',
    };
    final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson');
    final res = await http.get(url, headers: {
      'User-Agent': 'WanderlyApp/1.0 (+https://wanderly.example)'
    });
    if (res.statusCode != 200) {
      throw Exception('Routing error: ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final routes = body['routes'] as List<dynamic>?
        ?? (throw Exception('No routes in response'));
    if (routes.isEmpty) throw Exception('No route found');
    final geometry = (routes.first as Map<String, dynamic>)['geometry']
        as Map<String, dynamic>?;
    if (geometry == null) throw Exception('No geometry');
    final coords = geometry['coordinates'] as List<dynamic>;
    // OSRM returns [lon, lat]; convert to [lat, lon]
    return coords.map<List<double>>((c) {
      final lon = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      return [lat, lon];
    }).toList();
  }
}