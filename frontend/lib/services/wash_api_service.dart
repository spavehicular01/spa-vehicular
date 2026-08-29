import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wash_service.dart' as model;
import 'api_config.dart';

class WashApiService {
  // ==========================================
  // HELPER PARA CABECERAS CON AUTENTICACIÓN
  // ==========================================
  static Future<Map<String, String>> _getHeaders({bool authRequerida = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (authRequerida) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Helper para detectar la extensión de la imagen
  static String _obtenerSubtipo(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'png') return 'png';
    if (ext == 'webp') return 'webp';
    if (ext == 'heic') return 'heic';
    return 'jpeg';
  }

  // ==========================================
  // METODOS DE SUBIDA DE IMAGENES (CLOUD)
  // ==========================================
  static Future<String?> subirImagen(XFile imagen) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/upload');
      final request = http.MultipartRequest('POST', url);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final bytes = await imagen.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imagen.name,
          contentType: MediaType.parse('image/${_obtenerSubtipo(imagen.name)}'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return body['url'] ?? body['imageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('ERROR SUBIR IMAGEN: $e');
      return null;
    }
  }

  // ==========================================
  // METODOS DE VEHÍCULOS
  // ==========================================
  static Future<bool> registrarVehiculo(Map<String, dynamic> datosVehiculo) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles');
      final headers = await _getHeaders();
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(datosVehiculo),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR REGISTRAR VEHICULO: $e');
      return false;
    }
  }

  static Future<List<dynamic>> obtenerVehiculos(String usuarioId) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/usuario/$usuarioId');
      final headers = await _getHeaders();

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      debugPrint('ERROR OBTENER VEHICULOS: $e');
      return [];
    }
  }

  // ==========================================
  // METODOS DE SERVICIOS (CATÁLOGO DE LAVADOS)
  // ==========================================
  static Future<List<model.WashService>> getLavados() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/services');
      final headers = await _getHeaders(authRequerida: false);
      headers['Cache-Control'] = 'no-cache';

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body
            .map((dynamic item) =>
                model.WashService.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ERROR GET LAVADOS: $e');
      return [];
    }
  }

  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    required double precio,
    String? image,
  }) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/services');
      final headers = await _getHeaders();

      final Map<String, dynamic> bodyData = {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
      };

      if (image != null && image.trim().isNotEmpty) {
        bodyData['image'] = image;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      debugPrint('STATUS CREAR: ${response.statusCode}');
      debugPrint('BODY CREAR: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR CATCH CREAR: $e');
      return false;
    }
  }

  static Future<bool> actualizarServicio({
    required String id,
    required String nombre,
    required String descripcion,
    required double precio,
    String? image,
  }) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/services/$id');
      final headers = await _getHeaders();

      final Map<String, dynamic> bodyData = {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
      };

      if (image != null && image.trim().isNotEmpty) {
        bodyData['image'] = image;
      }

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(bodyData),
      );

      debugPrint('STATUS ACTUALIZAR: ${response.statusCode}');
      debugPrint('BODY ACTUALIZAR: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR CATCH ACTUALIZAR: $e');
      return false;
    }
  }

  static Future<bool> eliminarServicio(String id) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/services/$id');
      final headers = await _getHeaders();

      final response = await http.delete(
        url,
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('ERROR ELIMINAR SERVICIO: $e');
      return false;
    }
  }

  // ==========================================
  // METODOS DE CITAS / AGENDAMIENTO
  // ==========================================
  static Future<bool> crearCita(Map<String, dynamic> datosCita) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/appointments');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(datosCita),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR CREAR CITA: $e');
      return false;
    }
  }

  static Future<List<dynamic>> obtenerCitas(String usuarioId) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/appointments/usuario/$usuarioId');
      final headers = await _getHeaders();

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      debugPrint('ERROR OBTENER CITAS: $e');
      return [];
    }
  }

  static Future<List<dynamic>> obtenerTodasLasCitas() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/appointments');
      final headers = await _getHeaders();

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      debugPrint('ERROR OBTENER TODAS LAS CITAS: $e');
      return [];
    }
  }

  static Future<bool> actualizarEstadoCita(String citaId, String nuevoEstado) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/appointments/estado/$citaId');
      final headers = await _getHeaders();

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'estado': nuevoEstado}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR ACTUALIZAR ESTADO CITA: $e');
      return false;
    }
  }
}