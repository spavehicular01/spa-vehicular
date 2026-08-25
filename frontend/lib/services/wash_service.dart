import 'package:http/http.dart' as http;
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wash_service.dart';
import 'api_config.dart';

class WashApiService {
  // Función auxiliar para obtener el token JWT guardado en el dispositivo
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Ajusta 'token' según como guardes el JWT al hacer login
  }

  // 1. Obtener la lista de servicios (Pública)
  static Future<List<WashService>> getLavados() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
=======
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

// 1. Modelo de datos para mapear los lavados desde MongoDB
class WashService {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String image;

  WashService({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.image,
  });

  factory WashService.fromJson(Map<String, dynamic> json) {
    return WashService(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? json['name'] ?? '',
      descripcion: json['descripcion'] ?? json['description'] ?? '',
      precio: (json['precio'] ?? json['price'] ?? 0).toDouble(),
      image: json['image'] ?? json['imageUrl'] ?? '',
>>>>>>> origin/feature/diego
    );
  }

<<<<<<< HEAD
  // 2. Crear un nuevo servicio de lavado (Protegida)
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

  // 3. Crear y agendar cita (Protegida con JWT)
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

  // 4. Obtener citas programadas (Protegida con JWT)
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
      List<dynamic> todas = jsonDecode(response.body);
      return todas.where((c) => c['estado'] == 'pendiente' || c['estado'] == 'confirmada').toList();
    } else {
      throw Exception('Error al cargar lavadas programadas (Código: ${response.statusCode})');
    }
  }

  // 5. Obtener el historial de citas (Protegida con JWT)
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
=======
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'image': image,
    };
  }

  // 2. Conservamos tu método helper para convertir las imágenes
  static Future<http.MultipartFile> archivoImagen(XFile imagen) async {
    final bytes = await imagen.readAsBytes();
    return http.MultipartFile.fromBytes(
      'imagen',
      bytes,
      contentType: MediaType('image', 'jpeg'),
      filename: 'servicio_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
>>>>>>> origin/feature/diego
  }
}