import 'package:http/http.dart' as http;
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
    );
  }

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
  }
}