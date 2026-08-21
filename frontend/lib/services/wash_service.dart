import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class WashService {
  
  // Convierte la imagen seleccionada a MultipartFile para enviarla al backend
  static Future<http.MultipartFile> _archivoImagen(XFile imagen) async {
    final bytes = await imagen.readAsBytes();
    return http.MultipartFile.fromBytes(
      'imagen',
      bytes,
      contentType: MediaType('image', 'jpeg'),
      filename: 'servicio_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

}