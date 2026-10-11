import 'package:dio/dio.dart';

import 'failures.dart';

/// Ejecuta una llamada y garantiza que lo único que escapa es un [Failure].
/// Úsalo en los repositorios (capa data) para no filtrar `DioException`.
Future<T> guardFailure<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Failure {
    rethrow;
  } on DioException catch (e) {
    final inner = e.error;
    throw inner is Failure ? inner : const UnknownFailure();
  } on TypeError catch (e) {
    // JSON con forma inesperada (campo faltante o tipo distinto).
    throw ServerFailure('Respuesta con formato inesperado: $e');
  } on FormatException catch (e) {
    throw ServerFailure('Respuesta inválida: ${e.message}');
  }
}
