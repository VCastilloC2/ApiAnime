import 'package:dio/dio.dart';

/// Mide el tiempo ida y vuelta de cada petición y lo guarda en `extra['rtt_ms']`.
/// `ApiClient` lo lee para construir [ApiResponse.roundTripMs].
class TimingInterceptor extends Interceptor {
  static const startKey = 't0_us';
  static const rttKey = 'rtt_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[startKey] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final t0 = response.requestOptions.extra[startKey] as int?;
    if (t0 != null) {
      response.requestOptions.extra[rttKey] =
          ((DateTime.now().microsecondsSinceEpoch - t0) / 1000).round();
    }
    handler.next(response);
  }
}
