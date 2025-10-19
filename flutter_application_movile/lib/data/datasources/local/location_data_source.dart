import 'package:geolocator/geolocator.dart';

class LocationDataSource {
  /// Verifica y solicita permisos de ubicación
  Future<LocationPermission> _checkPermissions() async {
    // Verificar si los servicios de ubicación están habilitados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Solicitar permisos si están denegados
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }
    
    return permission;
  }

  /// Obtiene la ubicación actual del dispositivo
  Future<Position> getCurrentLocation() async {
    try {
      // Verificar y obtener permisos
      await _checkPermissions();

      // Obtener ubicación actual con alta precisión
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
    } on LocationServiceDisabledException {
      throw Exception(
          'Los servicios de ubicación están desactivados. Por favor, actívalos en la configuración de tu dispositivo.');
    } on LocationPermissionDeniedException {
      throw Exception(
          'Permisos de ubicación denegados. La aplicación necesita acceso a tu ubicación para recomendarte lugares cercanos.');
    } on LocationPermissionPermanentlyDeniedException {
      throw Exception(
          'Permisos de ubicación denegados permanentemente. Por favor, habilita los permisos manualmente en la configuración de la aplicación.');
    } catch (e) {
      throw Exception('Error al obtener la ubicación: $e');
    }
  }

  /// Obtiene la última ubicación conocida (más rápido pero posiblemente desactualizada)
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Calcula la distancia entre dos puntos en metros
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Escucha cambios en la ubicación en tiempo real
  Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metros
      ),
    );
  }
}

// Excepciones personalizadas para mejor manejo de errores
class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}

class LocationPermissionPermanentlyDeniedException implements Exception {}