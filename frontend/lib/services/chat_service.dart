import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
class ChatService {
  static String get _chatUrl => '${ApiConfig.baseUrl}/chat';

  static Future<String> enviarMensaje(String mensaje) async {
    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mensaje': mensaje}),
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