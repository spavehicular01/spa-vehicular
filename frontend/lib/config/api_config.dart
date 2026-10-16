import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

/// Única fuente de la dirección del servidor para toda la app.
///
/// Para probar en un celular real, o apuntar a un servidor publicado, sin editar código:
///   flutter run --dart-define=API_URL=http://192.168.1.10:3000/api
class ApiConfig {
  static const String _urlPersonalizada = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlPersonalizada.isNotEmpty) {
      return _urlPersonalizada;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Loopback especial para el emulador de Android
      return 'http://10.0.2.2:3000/api';
    }

    // iOS Simulator, macOS, Windows o Linux
    return 'http://localhost:3000/api';
  }
}