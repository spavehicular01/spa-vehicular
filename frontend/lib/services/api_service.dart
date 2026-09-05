import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configuración de URL base para emulador Android
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Helper privado para construir headers con Token JWT
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 0. Inicio de sesión y guardado de token JWT
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'), // Ajustado a la ruta estándar de autenticación
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'correo': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      final bool exito = response.statusCode == 200;

      if (exito && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }

      return {
        'success': exito,
        'message': data['mensaje'] ?? data['message'] ?? data['error'] ?? 'Error al iniciar sesión',
        'usuario': data['usuario'],
        'token': data['token'],
      };
    } catch (e) {
      debugPrint('Excepción en login: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor: $e'};
    }
  }

  // 1. Obtener todas las citas para el Administrador
  static Future<List<dynamic>> obtenerTodasLasCitas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
      );

      debugPrint('GET Citas Admin Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error en GET /appointments: ${response.body}');
        throw Exception('Error al obtener citas del servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Excepción al obtener citas: $e');
      rethrow;
    }
  }

  // 2. Obtener citas específicas de un usuario/cliente
  static Future<List<dynamic>> obtenerCitas(String usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/usuario/$usuarioId'),
        headers: headers,
      );

      debugPrint('GET Citas Usuario Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error en GET /appointments/usuario: ${response.body}');
        throw Exception('Error al obtener las citas del usuario (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Excepción al obtener citas del usuario: $e');
      rethrow;
    }
  }

  // 3. Crear / Agendar una nueva cita
  static Future<bool> crearCita(Map<String, dynamic> datosCita) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Enviando datos de cita: ${jsonEncode(datosCita)}');

      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
        body: jsonEncode(datosCita),
      );

      debugPrint('POST Crear Cita Status: ${response.statusCode}');
      debugPrint('POST Respuesta Servidor: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Excepción al agendar cita: $e');
      return false;
    }
  }

  // 4. Actualizar estado de cita (Para Admin)
  static Future<bool> actualizarEstadoCita(String citaId, String nuevoEstado) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/appointments/estado/$citaId'),
        headers: headers,
        body: jsonEncode({'estado': nuevoEstado}),
      );

      debugPrint('PUT Estado Cita Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Excepción al actualizar estado: $e');
      return false;
    }
  }
}