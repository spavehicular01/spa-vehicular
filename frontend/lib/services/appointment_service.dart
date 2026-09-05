import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart'; // Asegura usar la URL dinámica centralizada

class AppointmentService {
  // Se utiliza ApiConfig para manejar IPs dinámicas (ej: 10.0.2.2 en Emulador o localhost en Web/Físico)
  static String get _baseUrl => '${ApiConfig.baseUrl}/appointments';

  // Helper interno para incluir token JWT en peticiones que lo requieran
  static Future<Map<String, String>> _getHeaders({bool requiereAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (requiereAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // 1. Obtener citas por ID de usuario
  static Future<List<dynamic>> obtenerCitasUsuario(String usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/usuario/$usuarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      debugPrint('ERROR OBTENER CITAS USUARIO: $e');
      return [];
    }
  }

  // 2. Obtener citas por fecha (Filtro para vista Calendario)
  static Future<List<dynamic>> obtenerCitasPorFecha(String fecha, {String? token}) async {
    try {
      final headers = await _getHeaders();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/fecha/$fecha'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      debugPrint('ERROR OBTENER CITAS POR FECHA: $e');
      return [];
    }
  }

  // 3. Crear una nueva cita
  static Future<Map<String, dynamic>> crearCita(Map<String, dynamic> datosCita, {String? token}) async {
    try {
      final headers = await _getHeaders();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(datosCita),
      );

      // Logs de depuración para inspeccionar la respuesta en consola
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final data = jsonDecode(response.body);
      final bool exito = response.statusCode == 201 || response.statusCode == 200;

      return {
        'success': exito,
        'message': data['mensaje'] ??
            data['message'] ??
            data['error'] ??
            (exito ? 'Cita agendada exitosamente' : 'Error al agendar cita'),
        'cita': data['cita'] ?? data,
      };
    } catch (e) {
      debugPrint('ERROR CREAR CITA: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor: $e'};
    }
  }

  // 4. Reprogramar cita
  static Future<bool> reprogramarCita(String citaId, String nuevaFecha, String motivo) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'nuevaFecha': nuevaFecha,
        'fecha': nuevaFecha, // Compatibilidad con diferentes esquemas en Node.js
        'motivo': motivo,
      });

      // Intento 1: Ruta específica /reprogramar/:id
      var response = await http.put(
        Uri.parse('$_baseUrl/reprogramar/$citaId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      // Intento 2: Ruta REST estándar /appointments/:id
      response = await http.put(
        Uri.parse('$_baseUrl/$citaId'),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('ERROR REPROGRAMAR CITA: $e');
      return false;
    }
  }
}