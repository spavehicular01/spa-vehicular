import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VehicleService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/vehicles';

  static Map<String, String> _headers(String? token) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Extrae la lista de vehículos sin importar cómo la nombre el backend.
  static List<dynamic> _extraerLista(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['vehicles', 'vehiculos', 'vehicle', 'data', 'results']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return [];
  }

  static Future<List<dynamic>> obtenerVehiculos(String userId, {String? token}) async {
    try {
      final url = Uri.parse('$_baseUrl/usuario/$userId');
      debugPrint('GET VEHICULOS -> $url');

      final response = await http.get(url, headers: _headers(token));

      debugPrint('GET VEHICULOS STATUS: ${response.statusCode}');
      debugPrint('GET VEHICULOS BODY: ${response.body}');

      if (response.statusCode == 200) {
        return _extraerLista(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('GET VEHICULOS ERROR: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> registrarVehiculo({
    required String usuarioId,
    required String placa,
    required String marca,
    required String referencia,
    required String modelo,
    required String tipoVehiculo,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registrar'),
        headers: _headers(token),
        body: jsonEncode({
          'usuarioId': usuarioId,
          'placa': placa,
          'marca': marca,
          'referencia': referencia,
          'modelo': modelo,
          'tipoVehiculo': tipoVehiculo,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['mensaje'] ?? 'Respuesta del servidor',
        'vehicle': data['vehicle'],
      };
    } catch (e) {
      debugPrint('POST VEHICULO ERROR: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  static Future<bool> eliminarVehiculo(String vehicleId, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$vehicleId'),
        headers: _headers(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DELETE VEHICULO ERROR: $e');
      return false;
    }
  }
}
