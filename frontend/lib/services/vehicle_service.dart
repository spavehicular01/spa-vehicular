import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/vehicles';

  static Future<List<dynamic>> obtenerVehiculos(String userId, {String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/usuario/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        return data['vehicles'] ?? [];
      }
      return [];
    } catch (e) {
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
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
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
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  static Future<bool> eliminarVehiculo(String vehicleId, {String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/$vehicleId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}