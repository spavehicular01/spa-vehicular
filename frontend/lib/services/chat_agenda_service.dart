import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Respuesta del asesor virtual.
/// [accion] viene cuando el asesor dejó una cita lista para confirmar:
/// { 'tipo': 'confirmar_cita', 'datos': {...} }
class RespuestaChat {
  final String texto;
  final String? textoVoz; // versión corta para leer en voz alta
  final Map<String, dynamic>? accion;

  const RespuestaChat(this.texto, {this.textoVoz, this.accion});
}

/// Chat del cliente con capacidad de agendar citas.
/// El chat del administrador sigue usando ChatService.
class ChatAgendaService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/chat';

  // Render (plan gratis) se duerme: la primera respuesta puede tardar.
  static const Duration _espera = Duration(seconds: 60);

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Envía un mensaje al asesor. Con sesión iniciada puede agendar.
  static Future<RespuestaChat> enviarMensaje(
    String mensaje, {
    List<Map<String, String>> historial = const [],
    bool porVoz = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: await _headers(),
            body: jsonEncode({
              'mensaje': mensaje,
              'historial': historial,
              'porVoz': porVoz,
            }),
          )
          .timeout(_espera);

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return RespuestaChat(
          (data['message'] ?? 'El asesor no está disponible en este momento.').toString(),
        );
      }

      final accion = data['accion'];
      return RespuestaChat(
        (data['respuesta'] ?? 'No pude generar una respuesta.').toString(),
        textoVoz: data['respuestaVoz']?.toString(),
        accion: accion is Map ? Map<String, dynamic>.from(accion) : null,
      );
    } on TimeoutException {
      return const RespuestaChat(
        'El asesor tardó en responder. Intenta de nuevo en unos segundos.',
      );
    } catch (e) {
      print('⚠️ ERROR CHAT: $e');
      return const RespuestaChat(
        'No pude conectar con el asesor. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Confirma la cita que el asesor dejó propuesta.
  /// Devuelve { 'ok': bool, 'mensaje': String, 'red': bool }.
  /// 'red' = true cuando falló la conexión (se puede reintentar la misma propuesta).
  static Future<Map<String, dynamic>> confirmarCita(Map<String, dynamic> datos) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/confirmar-cita'),
            headers: await _headers(),
            body: jsonEncode({'datos': datos}),
          )
          .timeout(_espera);

      final data = jsonDecode(response.body);
      final exito = response.statusCode == 201 || response.statusCode == 200;

      if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'ok': false,
          'red': false,
          'mensaje': 'Tu sesión venció. Inicia sesión de nuevo para agendar.',
        };
      }

      return {
        'ok': exito,
        'red': false,
        'mensaje': (data['mensaje'] ??
                data['error'] ??
                (exito ? 'Cita agendada.' : 'No se pudo agendar la cita.'))
            .toString(),
      };
    } on TimeoutException {
      return {
        'ok': false,
        'red': true,
        'mensaje': 'El servidor tardó en responder. Toca Confirmar para intentar de nuevo.',
      };
    } catch (e) {
      print('⚠️ ERROR CONFIRMAR CITA: $e');
      return {
        'ok': false,
        'red': true,
        'mensaje': 'No pude conectar con el servidor. Toca Confirmar para intentar de nuevo.',
      };
    }
  }
}