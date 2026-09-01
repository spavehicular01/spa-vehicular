import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class UserService {
  // Ajusta a 10.0.2.2 para emulador Android o localhost para Windows/Desktop
  static const String _baseUrl = 'http://10.0.2.2:3000/api/users';

  // Actualizar datos del perfil del usuario (con opción de foto)
  static Future<Map<String, dynamic>> actualizarPerfil({
    required String id,
    required String nombres,
    required String apellidos,
    required String celular,
    File? imagen,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');

      // Si no hay imagen, hacemos una petición PUT normal tipo JSON
      if (imagen == null) {
        final response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombres': nombres,
            'apellidos': apellidos,
            'celular': celular,
          }),
        );

        final data = jsonDecode(response.body);
        return {
          'success': response.statusCode == 200,
          'message': data['mensaje'] ?? 'Perfil actualizado correctamente',
          'usuario': data['usuario'],
        };
      } 

      // Si viene una imagen, usamos MultipartRequest para enviar el archivo
      var request = http.MultipartRequest('PUT', uri);

      request.fields['nombres'] = nombres;
      request.fields['apellidos'] = apellidos;
      request.fields['celular'] = celular;

      var stream = http.ByteStream(imagen.openRead());
      var length = await imagen.length();
      var multipartFile = http.MultipartFile(
        'avatar', // Nombre del campo que debe recibir el backend/multer
        stream,
        length,
        filename: imagen.path.split('/').last,
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ?? 'Perfil actualizado correctamente',
        'usuario': data['usuario'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }
}