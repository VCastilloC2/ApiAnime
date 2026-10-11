import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_response.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/timing_interceptor.dart';

/// Construye el [Dio] base con todos los interceptores.
/// Orden importa: timing -> retry -> auth -> error (el error se mapea al final).
Dio buildDio({required TokenStorage tokenStorage, void Function()? onSessionExpired}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      headers: const {'Accept': 'application/json'},
      // Deja que Dio lance excepción en 4xx/5xx; ErrorInterceptor las tipa.
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ),
  );

  dio.interceptors.addAll([
    TimingInterceptor(),
    RetryInterceptor(dio: dio),
    AuthInterceptor(storage: tokenStorage, dio: dio, onSessionExpired: onSessionExpired),
    ErrorInterceptor(),
  ]);
  return dio;
}

/// Envoltorio con tipado genérico: cada llamada recibe un `parser` que convierte
/// el JSON en tu modelo, y devuelve [ApiResponse<T>] con metadatos de FastAPI.
class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic json) parser,
    CancelToken? cancelToken,
  }) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query, cancelToken: cancelToken), parser);

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    required T Function(dynamic json) parser,
  }) =>
      _send(() => _dio.post<dynamic>(path, data: body), parser);

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    required T Function(dynamic json) parser,
  }) =>
      _send(() => _dio.put<dynamic>(path, data: body), parser);

  /// FastAPI responde 204 sin cuerpo en DELETE.
  Future<void> delete(String path) => _send<void>(() => _dio.delete<dynamic>(path), (_) {});

  Future<ApiResponse<T>> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic json) parser,
  ) async {
    final res = await request();
    return ApiResponse<T>(
      data: parser(res.data),
      totalCount: int.tryParse(res.headers.value('x-total-count') ?? ''),
      serverTimeMs: double.tryParse(res.headers.value('x-process-time-ms') ?? ''),
      roundTripMs: (res.requestOptions.extra[TimingInterceptor.rttKey] as int?) ?? 0,
    );
  }
}
