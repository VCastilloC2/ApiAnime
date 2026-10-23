import 'package:flutter/foundation.dart';

/// Configuración de entorno.
///
/// Sobrescribe en build/run con:
///   flutter run -d chrome --dart-define=API_BASE_URL=https://api-anime-python-556r69ozu.vercel.app
class Env {
  const Env._();

  static const String _override = String.fromEnvironment('https://api-anime-python-556r69ozu.vercel.app');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'https://api-anime-python-556r69ozu.vercel.app';
    // Emulador Android: 10.0.2.2 es el localhost del PC.
    // Celular físico: usa --dart-define con la IP de tu PC (http://192.168.x.x:8000).
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://api-anime-python-556r69ozu.vercel.app';
    }
    return 'https://api-anime-python-556r69ozu.vercel.app';
  }

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Intervalo del monitor de latencia en tiempo real.
  static const Duration latencyPollInterval = Duration(seconds: 3);
}
