sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Error de red. Comprueba tu conexión.']);
}

final class AuthException extends AppException {
  const AuthException([super.message = 'Error de autenticación.']);
}

final class PermissionException extends AppException {
  const PermissionException([super.message = 'No tienes permisos para realizar esta acción.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Recurso no encontrado.']);
}

final class CapacityException extends AppException {
  const CapacityException([super.message = 'No quedan plazas disponibles.']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Ha ocurrido un error inesperado.']);
}
