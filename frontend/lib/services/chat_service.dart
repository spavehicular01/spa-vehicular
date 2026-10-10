import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ChatService {
  static String get _chatUrl => '${ApiConfig.baseUrl}/chat';

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
}
