import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Detecta cuando el servidor rechaza el token (vencido, firma inválida o ausente)
/// y avisa a la app para que cierre la sesión y mande al login.
///
/// Uso en los servicios: envolver cada respuesta con `SessionGuard.revisar(...)`.
class SessionGuard {
  /// Se incrementa cada vez que se detecta una sesión vencida.
  /// MainNavigationScreen escucha este valor y cierra la sesión.
  static final ValueNotifier<int> sesionExpirada = ValueNotifier<int>(0);

  static http.Response revisar(http.Response response) {
    if (_tokenRechazado(response)) {
      debugPrint('SessionGuard: token rechazado (${response.statusCode}), cerrando sesión');
      _limpiarToken();
      sesionExpirada.value++;
    }
    return response;
  }

  static bool _tokenRechazado(http.Response response) {
    if (response.statusCode == 401) return true;

    // El 403 también se usa para "solo administradores": ahí NO se cierra la sesión.
    if (response.statusCode == 403) {
      return response.body.contains('Token inválido');
    }
    return false;
  }

  static Future<void> _limpiarToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } catch (_) {}
  }
}