import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, TargetPlatform, defaultTargetPlatform;

/// Única fuente de la dirección del servidor para toda la app.
///
/// Opciones, de mayor a menor prioridad:
///   1. flutter run --dart-define=API_URL=http://192.168.1.10:3000/api
///   2. La app compilada en modo release usa siempre el servidor de Render.
///   3. [usarServidorRemoto] = true -> prueba en debug contra Render.
///   4. Desarrollo local (emulador / localhost).
class ApiConfig {
  static const String _urlPersonalizada = String.fromEnvironment('API_URL');

  // Servidor publicado (termina en /api, igual que las demás)
  static const String _remoteUrl = 'https://spa-vehicular.onrender.com/api';

  /// true  = en debug la app habla con el servidor desplegado en Render.
  /// false = en debug la app habla con tu computador (npm start local).
  static const bool usarServidorRemoto = true;

  static String get baseUrl {
    if (_urlPersonalizada.isNotEmpty) {
      return _urlPersonalizada;
    }

    if (kReleaseMode || usarServidorRemoto) {
      return _remoteUrl;
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

  /// Dirección del servidor SIN el "/api" final.
  /// Es la que necesitan los WebSockets (socket.io).
  static String get serverUrl {
    final url = baseUrl;
    return url.endsWith('/api') ? url.substring(0, url.length - 4) : url;
  }
}