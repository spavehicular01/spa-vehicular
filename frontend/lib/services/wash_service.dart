import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wash_service.dart';
import 'api_config.dart';

class WashApiService {
  static Future<List<WashService>> getLavados() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/services'), // <-- Cambiado de /productos a /services
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
}