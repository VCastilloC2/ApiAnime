import 'package:dio/dio.dart';

import '../../error/failures.dart';

/// Traduce cualquier `DioException` a un [Failure] tipado y lo deja en `err.error`.
/// Entiende los formatos de error de FastAPI:
///   {"detail": "texto"}                                   -> HTTPException / handlers propios
///   {"detail": [{"loc": [...], "msg": "...", ...}, ...]}  -> 422 de Pydantic
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: map(err)));
  }

  /// Público para poder probarlo sin montar la cadena de interceptores.
  Failure map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.cancel:
        return const UnknownFailure('Petición cancelada.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Certificado SSL inválido.');
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
      case DioExceptionType.unknown:
        return e.error is Failure ? e.error! as Failure : const NetworkFailure();
    }
  }

  Failure _fromResponse(Response<dynamic>? res) {
    final status = res?.statusCode ?? 0;
    final (message, fields) = _parseDetail(res?.data);

    if (status == 401 || status == 403) return UnauthorizedFailure(message ?? 'No autorizado.');
    if (status == 404) return NotFoundFailure(message ?? 'Recurso no encontrado.');
    if (status == 400 || status == 409 || status == 422) {
      return ValidationFailure(message ?? 'Datos inválidos.', fieldErrors: fields);
    }
    if (status == 503) return ServerFailure(message ?? 'Servicio no disponible (¿base de datos caída?).', statusCode: status);
    return ServerFailure(message ?? 'Error del servidor ($status).', statusCode: status);
  }

  (String?, Map<String, String>) _parseDetail(dynamic data) {
    if (data is! Map || !data.containsKey('detail')) return (null, const {});
    final detail = data['detail'];
    if (detail is String) return (detail, const {});
    if (detail is List) {
      final fields = <String, String>{};
      for (final item in detail) {
        if (item is Map) {
          final loc = item['loc'];
          // loc = ["body", "title"] -> campo = "title"
          final field = loc is List && loc.isNotEmpty ? loc.last.toString() : '_';
          fields[field] = (item['msg'] ?? 'Valor inválido').toString();
        }
      }
      final summary = fields.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
      return (summary.isEmpty ? null : summary, fields);
    }
    return (null, const {});
  }
}
