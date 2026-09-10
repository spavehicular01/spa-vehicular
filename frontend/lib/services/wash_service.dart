import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import 'api_config.dart';

class WashApiService {
  // Helper para obtener el token JWT
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. Obtener la lista de servicios
  static Future<List<ServiceModel>> getLavados() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => ServiceModel.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar servicios (${response.statusCode})');
    }
  }

  // 2. Crear un nuevo servicio de lavado
  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    double? precio,
    List<PrecioVehiculo>? precios,
    int duracionEstimadaMinutos = 30,
  }) async {
    final token = await _getToken();

    final Map<String, dynamic> bodyPayload = {
      'nombre': nombre, // Se mapea 'nombre' para coincidir con Node.js
      'nombreServicio': nombre, // Compatibilidad retroactiva
      'descripcion': descripcion,
      'duracionEstimadaMinutos': duracionEstimadaMinutos,
    };

    if (precios != null && precios.isNotEmpty) {
      bodyPayload['precios'] = precios.map((p) => p.toJson()).toList();
    } else if (precio != null) {
      bodyPayload['precio'] = precio;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyPayload),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 3. Crear y agendar cita
  static Future<bool> crearCita(Map<String, dynamic> citaData) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(citaData),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 4. Obtener todas las citas para el Panel Admin (WashManagementScreen)
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
      final body = jsonDecode(response.body);
      return body is List ? body : [];
    } else {
      throw Exception('Error al cargar lavadas programadas (Código: ${response.statusCode})');
    }
  }

  // 5. Obtener el historial de citas por estado completado
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
      final body = jsonDecode(response.body);
      return body is List ? body : [];
    } else {
      throw Exception('Error al cargar el historial (Código: ${response.statusCode})');
    }
  }

  // 6. Cambiar estado de una cita (Completado, Cancelado, En Proceso)
  static Future<bool> actualizarEstadoCita(String citaId, String nuevoEstado) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/appointments/estado/$citaId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'estado': nuevoEstado}),
    );

    return response.statusCode == 200;
  }
}