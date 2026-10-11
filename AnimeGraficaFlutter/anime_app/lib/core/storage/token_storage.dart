import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstracción para poder cambiar el almacenamiento (o mockearlo en tests).
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save({required String accessToken, String? refreshToken});
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  final FlutterSecureStorage _storage;

  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _access);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refresh);

  @override
  Future<void> save({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _access, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refresh, value: refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}
