import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/auth';

  // 🟢 Reemplaza con tu Client ID de tipo "Web" (el mismo que usa GOOGLE_CLIENT_ID en tu backend)
  static const String _webClientId = '903465087225-moalp2u8tjmuhe4ffct48nq0mnlucvi6.apps.googleusercontent.com';
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _webClientId,
  );

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
        'token': data['token'],
        'requiereVerificacion': data['requiereVerificacion'] == true,
        'email': data['email'] ?? email,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // 🟢 NUEVO: Login con Google
  static Future<Map<String, dynamic>> loginConGoogle() async {
    try {
      // 1. Abre el selector de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el selector
        return {'success': false, 'message': 'Inicio de sesión cancelado'};
      }

      // 2. Obtiene el idToken (JWT) que espera tu backend
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'No se pudo obtener el token de Google'};
      }

      // 3. Manda el idToken a tu backend (ruta real: /login-google)
      final response = await http.post(
        Uri.parse('$_baseUrl/login-google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = jsonDecode(response.body);
      final bool exito = response.statusCode == 200;

      if (exito && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }

      return {
        'success': exito,
        'message': data['message'] ?? data['mensaje'] ?? 'Error al iniciar sesión con Google',
        'usuario': data['usuario'],
        'token': data['token'],
      };
    } catch (e) {
      print('⚠️ ERROR LOGIN GOOGLE: $e');
      return {'success': false, 'message': 'Error de conexión con Google: $e'};
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
          'email': correo,
          'correo': correo,
          'celular': celular,
          'telefono': celular,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

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