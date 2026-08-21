import 'dart:convert'; // Corregido: 'dart:convert' en lugar de 'dart0convert'
import 'package:http/http.dart' as http;
import '../models/wash_service.dart'; // Si tu archivo de modelo tiene otro nombre en lib/models, ajústalo aquí
import 'api_config.dart';

class WashApiService {
  // 1. Obtener la lista de servicios desde Node.js / Mongo Atlas
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
      throw Exception('Error al cargar servicios (Código: ${response.statusCode})');
    }
  }

  // 2. Crear un nuevo servicio de lavado (Para el panel de administración)
  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    required double precio,
    required String image,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Content-Type': 'application/json',
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

  // 3. Crear y agendar la cita final con el servicio seleccionado
  static Future<bool> crearCita(Map<String, dynamic> citaData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(citaData),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }
}