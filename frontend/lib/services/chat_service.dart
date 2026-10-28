import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'session_guard.dart';

class ChatService {
  static String get _chatUrl => '${ApiConfig.baseUrl}/chat';
  static String get _chatAdminUrl => '${ApiConfig.baseUrl}/chat/admin';

  /// Asesor virtual para CLIENTES (público, no necesita sesión).
  /// Envía el mensaje junto con los últimos mensajes de la conversación
  /// ([historial], con claves 'role' = 'user' | 'bot' y 'text'), para que el
  /// asesor entienda preguntas de seguimiento como "¿y cuánto dura?".
  static Future<String> enviarMensaje(
    String mensaje, {
    List<Map<String, String>> historial = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mensaje': mensaje,
          'historial': historial,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['respuesta'] ?? 'No se recibió respuesta del asesor.';
      } else {
        return 'El asesor virtual no está disponible en este momento.';
      }
    } catch (e) {
      return 'Error de conexión con el servidor del spa vehicular. Verifica tu red.';
    }
  }

  /// Asistente interno para el ADMINISTRADOR. Requiere sesión de administrador:
  /// el servidor rechaza a cualquier otro usuario.
  static Future<String> enviarMensajeAdmin(
    String mensaje, {
    List<Map<String, String>> historial = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = SessionGuard.revisar(await http
          .post(
            Uri.parse(_chatAdminUrl),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'mensaje': mensaje,
              'historial': historial,
            }),
          )
          .timeout(const Duration(seconds: 60)));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['respuesta'] ?? 'No se recibió respuesta del asistente.';
      }
      if (response.statusCode == 403) {
        return 'Este asistente es solo para el administrador.';
      }
      return 'El asistente no está disponible en este momento.';
    } catch (e) {
      return 'Error de conexión con el servidor del spa vehicular. Verifica tu red.';
    }
  }
}