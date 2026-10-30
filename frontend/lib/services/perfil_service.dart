import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'session_guard.dart';

class PerfilService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Devuelve el usuario tal como está guardado en el servidor,
  /// o null si no se pudo consultar (sin conexión, sesión vencida, etc.).
  static Future<Map<String, dynamic>?> obtenerMiPerfil() async {
    try {
      final headers = await _headers();
      final response = SessionGuard.revisar(await http
          .get(Uri.parse('${ApiConfig.baseUrl}/users/me'), headers: headers)
          .timeout(const Duration(seconds: 20)));

      debugPrint('GET /users/me -> ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final usuario = data['usuario'];
      return usuario is Map ? Map<String, dynamic>.from(usuario) : null;
    } catch (e) {
      debugPrint('Excepción al obtener mi perfil: $e');
      return null;
    }
  }

  /// Guarda apellido, documento y teléfono en la cuenta (queda en MongoDB para siempre).
  /// El apellido es opcional para no romper otros lugares que llamen este método.
  static Future<Map<String, dynamic>> completarPerfil({
    required String userId,
    required String documento,
    required String telefono,
    String apellidos = '',
  }) async {
    try {
      final headers = await _headers();
      final response = SessionGuard.revisar(await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/users/perfil/$userId'),
            headers: headers,
            body: jsonEncode({
              'documentoIdentidad': documento,
              'celular': telefono,
              if (apellidos.trim().isNotEmpty) 'apellidos': apellidos.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30)));

      final data = jsonDecode(response.body);
      final exito = response.statusCode == 200 && data['ok'] == true;

      return {
        'success': exito,
        'message': data['mensaje'] ??
            data['message'] ??
            'No se pudo guardar. Intenta de nuevo.',
        'usuario': data['usuario'],
      };
    } catch (e) {
      debugPrint('Excepción al completar perfil: $e');
      return {
        'success': false,
        'message': 'Error de conexión con el servidor',
      };
    }
  }
}