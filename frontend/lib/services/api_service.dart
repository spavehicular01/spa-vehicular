import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'session_guard.dart';

class ApiService {
  // La dirección del servidor sale de ApiConfig (un solo lugar para cambiarla)
  static String get baseUrl => ApiConfig.baseUrl;

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
        Uri.parse('$baseUrl/auth/login'),
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
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
      ));

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
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('$baseUrl/appointments/usuario/$usuarioId'),
        headers: headers,
      ));

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

      final response = SessionGuard.revisar(await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
        body: jsonEncode(datosCita),
      ));

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
      final response = SessionGuard.revisar(await http.patch(
        Uri.parse('$baseUrl/appointments/estado/$citaId'),
        headers: headers,
        body: jsonEncode({'estado': nuevoEstado}),
      ));

      debugPrint('PATCH Estado Cita Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Excepción al actualizar estado: $e');
      return false;
    }
  }

  // 5. Obtener todos los clientes con sus vehículos (Panel Admin)
  static Future<List<dynamic>> obtenerClientes() async {
    try {
      final headers = await _getHeaders();
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('$baseUrl/users/clientes'),
        headers: headers,
      ));

      debugPrint('GET Clientes Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error en GET /users/clientes: ${response.body}');
        throw Exception('Error al obtener clientes del servidor (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Excepción al obtener clientes: $e');
      rethrow;
    }
  }

  // 6. Actualizar el perfil del usuario (solo el dueño de la cuenta).
  // Se envía como multipart para poder subir la foto; la foto es opcional.
  static Future<Map<String, dynamic>> actualizarPerfil({
    required String userId,
    required String nombres,
    required String apellidos,
    required String celular,
    File? avatar,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/perfil/$userId'),
      );
      // Sin 'Content-Type': multipart lo genera solo con su boundary
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombres'] = nombres;
      request.fields['apellidos'] = apellidos;
      request.fields['celular'] = celular;

      if (avatar != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = SessionGuard.revisar(await http.Response.fromStream(streamed));

      debugPrint('PUT Perfil Status: ${response.statusCode}');
      debugPrint('PUT Perfil Respuesta: ${response.body}');

      final data = jsonDecode(response.body);
      final bool exito = response.statusCode == 200 && data['ok'] == true;

      return {
        'success': exito,
        'message': data['mensaje'] ?? data['message'] ?? data['error'] ?? 'No se pudo actualizar el perfil',
        'usuario': data['usuario'],
      };
    } catch (e) {
      debugPrint('Excepción al actualizar perfil: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // 7. Registrar el pago de una cita (solo Admin, al entregar el vehículo).
  // metodoPago: 'efectivo' | 'transferencia' | 'nequi' | 'daviplata' | 'tarjeta'
  // Si no se envía monto, el backend usa el precio guardado en la cita.
  static Future<Map<String, dynamic>> registrarPago({
    required String citaId,
    required String metodoPago,
    double? monto,
    String? referencia,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'citaId': citaId,
        'metodoPago': metodoPago,
        if (monto != null) 'monto': monto,
        if (referencia != null && referencia.trim().isNotEmpty)
          'referencia': referencia.trim(),
      };

      final response = SessionGuard.revisar(await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: headers,
        body: jsonEncode(body),
      ));

      debugPrint('POST Registrar Pago Status: ${response.statusCode}');
      debugPrint('POST Registrar Pago Respuesta: ${response.body}');

      final data = jsonDecode(response.body);
      final bool exito = response.statusCode == 200 || response.statusCode == 201;

      return {
        'success': exito,
        'message': data['mensaje'] ?? data['message'] ?? data['error'] ?? 'No se pudo registrar el pago',
        'pago': data['pago'],
        'cita': data['cita'],
      };
    } catch (e) {
      debugPrint('Excepción al registrar pago: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // 7.1 Resumen de pagos para el panel de reportes (solo Admin):
  // totales de hoy, semana y mes (con desglose por método) y lo pendiente por cobrar.
  static Future<Map<String, dynamic>> obtenerResumenPagos() async {
    try {
      final headers = await _getHeaders();
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('$baseUrl/payments/resumen'),
        headers: headers,
      ));

      debugPrint('GET Resumen Pagos Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      throw Exception('Error al obtener el resumen de pagos (${response.statusCode})');
    } catch (e) {
      debugPrint('Excepción al obtener resumen de pagos: $e');
      rethrow;
    }
  }

  // 8. Obtener las notificaciones guardadas de un usuario
  static Future<List<dynamic>> obtenerNotificaciones(String usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = SessionGuard.revisar(await http.get(
        Uri.parse('$baseUrl/notifications/usuario/$usuarioId'),
        headers: headers,
      ));

      debugPrint('GET Notificaciones Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener notificaciones (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Excepción al obtener notificaciones: $e');
      rethrow;
    }
  }

  // 9. Marcar una notificación como leída
  static Future<bool> marcarNotificacionLeida(String notificacionId) async {
    try {
      final headers = await _getHeaders();
      final response = SessionGuard.revisar(await http.patch(
        Uri.parse('$baseUrl/notifications/$notificacionId/leida'),
        headers: headers,
      ));

      debugPrint('PATCH Notificación leída Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Excepción al marcar notificación: $e');
      return false;
    }
  }

  // 10. Marcar todas las notificaciones de un usuario como leídas
  static Future<bool> marcarTodasLeidas(String usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = SessionGuard.revisar(await http.patch(
        Uri.parse('$baseUrl/notifications/usuario/$usuarioId/leidas'),
        headers: headers,
      ));

      debugPrint('PATCH Todas leídas Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Excepción al marcar todas como leídas: $e');
      return false;
    }
  }

  // 11. Eliminar una notificación
  static Future<bool> eliminarNotificacion(String notificacionId) async {
    try {
      final headers = await _getHeaders();
      final response = SessionGuard.revisar(await http.delete(
        Uri.parse('$baseUrl/notifications/$notificacionId'),
        headers: headers,
      ));

      debugPrint('DELETE Notificación Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Excepción al eliminar notificación: $e');
      return false;
    }
  }
}