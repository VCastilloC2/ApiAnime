import 'dart:math';

import 'package:dio/dio.dart';

/// Reintenta SOLO peticiones GET ante fallos transitorios de red/timeout
/// con backoff exponencial (400 ms, 800 ms, ...). POST/PUT/DELETE nunca se reintentan.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.maxRetries = 2});

  final Dio dio;
  final int maxRetries;
  static const _attemptKey = 'retry_attempt';

  bool _isTransient(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final attempt = (opts.extra[_attemptKey] as int?) ?? 0;

    if (opts.method != 'GET' || !_isTransient(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    await Future<void>.delayed(Duration(milliseconds: 400 * pow(2, attempt).toInt()));
    opts.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await dio.fetch<dynamic>(opts));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
