import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ajusta según la IP de tu servidor (10.0.2.2 para emulador Android)
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // 1. Obtener todas las citas para el Administrador
  static Future<List<dynamic>> obtenerTodasLasCitas() async {
    final response = await http.get(Uri.parse('$baseUrl/appointments'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener citas del servidor');
  }

  // 2. Obtener citas específicas de un usuario/cliente
  static Future<List<dynamic>> obtenerCitas(String usuarioId) async {
    final response = await http.get(Uri.parse('$baseUrl/appointments/usuario/$usuarioId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener las citas del usuario');
  }

  // 3. Actualizar estado de cita (Para Admin)
  static Future<bool> actualizarEstadoCita(String citaId, String nuevoEstado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/estado/$citaId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': nuevoEstado}),
    );

    return response.statusCode == 200;
  }
}