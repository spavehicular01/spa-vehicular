import 'dart:convert';
import 'package:http/http.dart' as http;

class AppointmentService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/appointments';

  // Obtener citas por ID de usuario
  static Future<List<dynamic>> obtenerCitasUsuario(String usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuario/$usuarioId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Crear una nueva cita
  static Future<Map<String, dynamic>> crearCita(Map<String, dynamic> datosCita) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datosCita),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['mensaje'] ?? 'Error al agendar cita',
        'cita': data['cita'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // Reprogramar cita
  static Future<bool> reprogramarCita(String citaId, String nuevaFecha, String motivo) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/reprogramar/$citaId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nuevaFecha': nuevaFecha,
          'motivo': motivo,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}