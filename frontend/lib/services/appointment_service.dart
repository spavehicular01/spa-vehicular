import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class AppointmentService {
  // 🟢 Obtener citas de una fecha específica (usado en CalendarScreen)
  static Future<List<dynamic>> obtenerCitasPorFecha(
    String fecha,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/date/$fecha'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'citas': data['citas'] ?? data,
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

  // 🟢 Cancelar una cita
  static Future<Map<String, dynamic>> cancelarCita(
    String citaId, {
    String? token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/appointments/$citaId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Cita cancelada correctamente',
        };
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo cancelar la cita',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}