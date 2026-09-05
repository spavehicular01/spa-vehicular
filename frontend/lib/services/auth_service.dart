import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/auth';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'correo': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      final bool exito = response.statusCode == 200;

      if (exito && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }

      return {
        'success': exito,
        'message': data['mensaje'] ?? data['message'] ?? 'Error al iniciar sesión',
        'usuario': data['usuario'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  static Future<Map<String, dynamic>> registrar({
    required String nombres,
    required String apellidos,
    required String documentoIdentidad,
    required String correo,
    required String celular,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombres': nombres,
          'apellidos': apellidos,
          'documentoIdentidad': documentoIdentidad,
          'email': correo,   // Envia 'email' por si el backend lo espera así
          'correo': correo,  // Envia 'correo' por compatibilidad
          'celular': celular,
          'telefono': celular, // Envia 'telefono' por compatibilidad
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // 🔍 IMPRESIONES DE DEPURACIÓN EN CONSOLA (DEBUG)
      print('=== DEBUG REGISTRO ===');
      print('Status Code: ${response.statusCode}');
      print('Respuesta Servidor: $data');
      print('======================');

      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'message': data['mensaje'] ?? data['error'] ?? data['message'] ?? 'Error al registrar usuario',
        'usuario': data['usuario'],
      };
    } catch (e) {
      print('⚠️ ERROR EXCEPCIÓN REGISTRO: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor: $e'};
    }
  }

  // 🟢 Método para verificar el código enviando correo y código de 6 dígitos
  static Future<Map<String, dynamic>> verificarCuenta({
    required String email,
    required String codigo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verificar-cuenta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'correo': email,
          'codigo': codigo,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ?? data['message'] ?? 'Error al verificar la cuenta',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // 🔄 Método para reenviar el código de verificación
  static Future<Map<String, dynamic>> reenviarCodigo({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reenviar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'correo': email,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ?? data['message'] ?? 'Nuevo código enviado',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  static Future<Map<String, dynamic>> solicitarCodigoRecuperacion(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recuperar/solicitar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'correo': email}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ?? data['message'] ?? 'Ocurrió un error',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  static Future<Map<String, dynamic>> restablecerPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recuperar/restablecer-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'correo': email,
          'codigo': codigo,
          'nuevaPassword': nuevaPassword,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['mensaje'] ?? data['message'] ?? 'Ocurrió un error',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }
}
