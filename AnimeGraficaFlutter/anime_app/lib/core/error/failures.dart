/// Errores tipados que viajan por todas las capas (data -> domain -> UI).
/// La capa de presentación nunca ve un `DioException`.
sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión con el servidor. Revisa tu red o que la API esté encendida.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'El servidor tardó demasiado en responder.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sesión expirada o no autorizada.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado.']);
}

/// 400/409/422 de FastAPI. `fieldErrors` mapea campo -> mensaje (formato Pydantic).
class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado.']);
}
