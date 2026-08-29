import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // Ajusta a 10.0.2.2 para emulador Android o localhost para Windows/Desktop
  static const String _baseUrl = 'http://10.0.2.2:3000/api/users';

  // Actualizar datos del perfil del usuario
  static Future<Map<String, dynamic>> actualizarPerfil({
    required String id,
    required String nombres,
    required String apellidos,
    required String celular,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
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
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }
}