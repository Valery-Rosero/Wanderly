abstract class LocationError {
  final String message;

  LocationError(this.message);
}

class LocationServiceDisabledError extends LocationError {
  LocationServiceDisabledError() 
      : super('Los servicios de ubicación están desactivados');
}

class LocationPermissionDeniedError extends LocationError {
  LocationPermissionDeniedError() 
      : super('Permisos de ubicación denegados');
}

class LocationPermissionPermanentlyDeniedError extends LocationError {
  LocationPermissionPermanentlyDeniedError() 
      : super('Permisos de ubicación denegados permanentemente');
}

class LocationTimeoutError extends LocationError {
  LocationTimeoutError() 
      : super('Tiempo de espera agotado al obtener la ubicación');
}