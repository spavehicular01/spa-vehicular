import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'session_guard.dart';

class UserService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/users';

  // Token JWT guardado al iniciar sesión
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // Actualizar datos del perfil del usuario (con opción de foto).
  // Todos los campos son opcionales: solo se envían los que traen valor.
  // `documentoIdentidad` el backend lo guarda una sola vez (no se puede cambiar).
  static Future<Map<String, dynamic>> actualizarPerfil({
    required String id,
    String nombres = '',
    String apellidos = '',
    String celular = '',
    String documentoIdentidad = '',
    File? imagen,
  }) async {
    try {
      // Ruta real del backend: PUT /api/users/perfil/:id
      final uri = Uri.parse('$_baseUrl/perfil/$id');
      final token = await _getToken();

      final campos = <String, String>{
        if (nombres.trim().isNotEmpty) 'nombres': nombres.trim(),
        if (apellidos.trim().isNotEmpty) 'apellidos': apellidos.trim(),
        if (celular.trim().isNotEmpty) 'celular': celular.trim(),
        if (documentoIdentidad.trim().isNotEmpty)
          'documentoIdentidad': documentoIdentidad.trim(),
      };

      // Si no hay imagen, hacemos una petición PUT normal tipo JSON
      if (imagen == null) {
        final response = SessionGuard.revisar(await http.put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(campos),
        ));

        final data = jsonDecode(response.body);
        return {
          'success': response.statusCode == 200,
          'message': data['mensaje'] ??
              data['message'] ??
              'Perfil actualizado correctamente',
          'usuario': data['usuario'],
        };
      }

      // Si viene una imagen, usamos MultipartRequest para enviar el archivo
      var request = http.MultipartRequest('PUT', uri);
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(campos);

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
      var response = SessionGuard.revisar(await http.Response.fromStream(streamedResponse));
      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ??
            data['message'] ??
            'Perfil actualizado correctamente',
        'usuario': data['usuario'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // Cambiar contraseña del usuario
  static Future<Map<String, dynamic>> cambiarPassword({
    required String id,
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    try {
      // Ruta del backend: PUT /api/users/perfil/:id/cambiar-password
      final uri = Uri.parse('$_baseUrl/perfil/$id/cambiar-password');
      final token = await _getToken();

      final response = SessionGuard.revisar(await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        // El controlador del backend lee currentPassword / newPassword;
        // se mandan ambos estilos de nombre para que siempre coincidan.
        body: jsonEncode({
          'passwordActual': passwordActual,
          'currentPassword': passwordActual,
          'nuevaPassword': nuevaPassword,
          'newPassword': nuevaPassword,
        }),
      ));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ??
            data['message'] ??
            'Contraseña actualizada correctamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión con el servidor',
      };
    }
  }
}