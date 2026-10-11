import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Emulador Android -> 10.0.2.2 apunta al localhost del PC.
  /// Celular físico: reemplaza por la IP de tu PC en la red (ej. http://192.168.1.10:8000).
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
