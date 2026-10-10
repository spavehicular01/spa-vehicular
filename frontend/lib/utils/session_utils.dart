import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Devuelve el id del usuario con sesión iniciada.
/// Primero usa 'userId' (guardado al iniciar sesión); si no está, lo saca del
/// token JWT (campo `id`), así no depende de que el login haya guardado 'userId'.
Future<String?> obtenerUserIdSesion([SharedPreferences? prefsExistentes]) async {
  final prefs = prefsExistentes ?? await SharedPreferences.getInstance();

  final guardado = prefs.getString('userId');
  if (guardado != null && guardado.isNotEmpty) return guardado;

  final id = _idDesdeToken(prefs.getString('token'));
  if (id != null) {
    // Se guarda para que el resto de la app lo encuentre directamente.
    await prefs.setString('userId', id);
  }
  return id;
}

String? _idDesdeToken(String? token) {
  try {
    if (token == null || token.isEmpty) return null;
    final partes = token.split('.');
    if (partes.length != 3) return null;
    final carga = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
    final datos = jsonDecode(carga) as Map<String, dynamic>;
    final id = (datos['id'] ?? datos['_id'] ?? datos['userId'])?.toString();
    return (id == null || id.isEmpty) ? null : id;
  } catch (_) {
    return null;
  }
}