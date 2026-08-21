import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wash_service.dart' as model;
import 'api_config.dart';

class WashApiService {
  // Obtener lista de servicios desde el backend
  static Future<List<model.WashService>> getLavados() async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/services');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body
          .map((dynamic item) =>
              model.WashService.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Error al cargar servicios (Código: ${response.statusCode})');
    }
  }

  // Crear un nuevo servicio
  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    required double precio,
    required String image,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/services');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'image': image,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }
}