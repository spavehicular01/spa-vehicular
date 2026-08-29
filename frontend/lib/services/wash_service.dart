import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wash_service.dart';
import 'api_config.dart';

class WashApiService {
  // Función auxiliar para obtener el token JWT guardado
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. Obtener la lista de servicios
  static Future<List<WashService>> getLavados() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => WashService.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar servicios');
    }
  }

  // 2. Crear un nuevo servicio de lavado
  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    required double precio,
    required String image,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'image': image,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 3. Crear y agendar cita
  static Future<bool> crearCita(Map<String, dynamic> citaData) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments/crear'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(citaData),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 4. Obtener todas las citas para que WashManagementScreen las distribuya por pestañas
  static Future<List<dynamic>> getCitasProgramadas() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appointments'),
      headers: {
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar lavadas programadas (Código: ${response.statusCode})');
    }
  }

  // 5. Obtener el historial de citas
  static Future<List<dynamic>> getHistorialCitas() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appointments?estado=completado'),
      headers: {
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar el historial (Código: ${response.statusCode})');
    }
  }
}