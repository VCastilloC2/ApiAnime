import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Adjunta `Authorization: Bearer` y, ante un 401, intenta refrescar el token
/// UNA vez y reintenta la petición original.
///
/// Tu API actual no exige autenticación, así que sin token guardado este
/// interceptor no hace nada. Queda listo para cuando agregues OAuth2/JWT en FastAPI.
// Nota: se usa Interceptor (no QueuedInterceptor) porque reintentar con el mismo
// Dio dentro de una cola provocaría un deadlock.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.dio,
    this.refreshToken,
    this.onSessionExpired,
  });

  final TokenStorage storage;

  /// Dio "principal" (sin este interceptor en la petición de refresco) para reintentar.
  final Dio dio;

  /// Llama a tu endpoint de refresh y devuelve el nuevo access token (o null).
  final Future<String?> Function(String refreshToken)? refreshToken;

  /// Se invoca si no se pudo renovar (p. ej. para navegar al login).
  final void Function()? onSessionExpired;

  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    final refresh = refreshToken;

    if (!is401 || alreadyRetried || refresh == null) {
      return handler.next(err);
    }

    final stored = await storage.readRefreshToken();
    final newToken = stored == null ? null : await refresh(stored);

    if (newToken == null) {
      await storage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    await storage.save(accessToken: newToken);
    try {
      final opts = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra[_retriedKey] = true;
      handler.resolve(await dio.fetch<dynamic>(opts));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
