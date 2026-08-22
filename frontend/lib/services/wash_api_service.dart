import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/wash_service.dart' as model;
import 'api_config.dart';

class WashApiService {
  // ==========================================
  // METODOS DE SUBIDA DE IMAGENES (CLOUD)
  // ==========================================

  // Subir imagen capturada/seleccionada al backend (Cloudinary)
  static Future<String?> subirImagen(XFile imagen) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/upload');
      final request = http.MultipartRequest('POST', url);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Nombre del campo que espera Multer en Express
          imagen.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return body['url']; // Retorna la URL generada en Cloudinary
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // METODOS DE VEHÍCULOS
  // ==========================================

  // Registrar un vehículo en la base de datos
  static Future<bool> registrarVehiculo(Map<String, dynamic> datosVehiculo) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datosVehiculo),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Obtener los vehículos asignados al usuario logueado
  static Future<List<dynamic>> obtenerVehiculos(String usuarioId) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/vehicles/usuario/$usuarioId');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // METODOS DE SERVICIOS (CATÁLOGO DE LAVADOS)
  // ==========================================

  static Future<List<model.WashService>> getLavados() async {
    try {
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
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    required double precio,
    required String image,
  }) async {
    try {
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
    } catch (e) {
      return false;
    }
  }

  // Eliminar un servicio por su ID
  static Future<bool> eliminarServicio(String id) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/services/$id');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // METODOS DE CITAS / AGENDAMIENTO
  // ==========================================

  // Crear una nueva cita (Usuario o Admin)
  static Future<bool> crearCita(Map<String, dynamic> datosCita) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/appointments');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datosCita),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Obtener citas de un usuario específico
  static Future<List<dynamic>> obtenerCitas(String usuarioId) async {
    try {
      final Uri url =
          Uri.parse('${ApiConfig.baseUrl}/appointments/usuario/$usuarioId');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Obtener todas las citas (Admin)
  static Future<List<dynamic>> obtenerTodasLasCitas() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/appointments');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Actualizar estado de la cita (Admin)
  static Future<bool> actualizarEstadoCita(
      String citaId, String nuevoEstado) async {
    try {
      final Uri url =
          Uri.parse('${ApiConfig.baseUrl}/appointments/estado/$citaId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}