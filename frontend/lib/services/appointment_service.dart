import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_guard.dart';

class AppointmentService {
  // El backend responde con 'mensaje' (a veces 'message'); se acepta cualquiera
  static String _mensaje(dynamic data, String porDefecto) {
    if (data is Map<String, dynamic>) {
      return (data['mensaje'] ?? data['message'] ?? data['error'] ?? porDefecto).toString();
    }
    return porDefecto;
  }

  // 🟢 Crear / Agendar una nueva cita (Usado en BookingController)
  static Future<Map<String, dynamic>> crearCita(
    Map<String, dynamic> datosCita, {
    String? token,
  }) async {
    try {
      final response = SessionGuard.revisar(await http.post(
        Uri.parse('${ApiConfig.baseUrl}/appointments'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(datosCita),
      ));

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _mensaje(data, 'Cita agendada con éxito'),
          'cita': (data is Map<String, dynamic> ? data['cita'] : null) ?? data,
        };
      }

      return {
        'success': false,
        'message': _mensaje(data, 'Error al agendar la cita (${response.statusCode})'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión al crear cita: $e',
      };
    }
  }

  // 🟢 Obtener citas de una fecha específica YYYY-MM-DD (usado en CalendarScreen)
  static Future<List<dynamic>> obtenerCitasPorFecha(
    String fecha,
    String token,
  ) async {
    try {
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/fecha/$fecha'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map<String, dynamic> && data['citas'] != null) {
          return data['citas'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 🟢 Obtener citas por ID de usuario
  static Future<Map<String, dynamic>> obtenerCitasPorUsuario(
    String userId, {
    String? token,
  }) async {
    try {
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/usuario/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

      if (response.statusCode == 200) {
        // El backend devuelve directamente una lista de citas
        final dynamic data = jsonDecode(response.body);
        return {
          'success': true,
          'citas': data is Map<String, dynamic> ? (data['citas'] ?? []) : data,
        };
      }
      return {
        'success': false,
        'message': 'Error al obtener citas (${response.statusCode})',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🟢 Cancelar una cita (el dueño de la cita o un administrador)
  static Future<Map<String, dynamic>> cancelarCita(
    String citaId, {
    String? token,
  }) async {
    try {
      final response = SessionGuard.revisar(await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/appointments/cancelar/$citaId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _mensaje(data, 'Cita cancelada correctamente'),
        };
      }

      return {
        'success': false,
        'message': _mensaje(data, 'No se pudo cancelar la cita'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}