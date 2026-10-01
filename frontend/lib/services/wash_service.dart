import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import 'api_config.dart';

/// Cupos de un día: cuántas citas activas hay por hora (hora local de Colombia, 0-23).
class CuposDia {
  final int limite;
  final Map<int, int> _ocupadasPorHora;

  const CuposDia({required this.limite, required Map<int, int> ocupadasPorHora})
      : _ocupadasPorHora = ocupadasPorHora;

  /// Día sin datos (o si falló la consulta): todo se considera libre.
  const CuposDia.vacio({this.limite = 5}) : _ocupadasPorHora = const {};

  int ocupadas(int hora) => _ocupadasPorHora[hora] ?? 0;
  int disponibles(int hora) => (limite - ocupadas(hora)).clamp(0, limite);
  bool estaLleno(int hora) => ocupadas(hora) >= limite;
}

class WashApiService {
  // Helper para obtener el token JWT
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. Obtener la lista de servicios
  static Future<List<ServiceModel>> getLavados() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => ServiceModel.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar servicios (${response.statusCode})');
    }
  }

  // 2. Crear un nuevo servicio de lavado
  static Future<bool> crearLavado({
    required String nombre,
    required String descripcion,
    double? precio,
    List<PrecioVehiculo>? precios,
    int duracionEstimadaMinutos = 30,
  }) async {
    final token = await _getToken();

    final Map<String, dynamic> bodyPayload = {
      'nombre': nombre, // Se mapea 'nombre' para coincidir con Node.js
      'nombreServicio': nombre, // Compatibilidad retroactiva
      'descripcion': descripcion,
      'duracionEstimadaMinutos': duracionEstimadaMinutos,
    };

    if (precios != null && precios.isNotEmpty) {
      bodyPayload['precios'] = precios.map((p) => p.toJson()).toList();
    } else if (precio != null) {
      bodyPayload['precio'] = precio;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyPayload),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  // 3. Crear y agendar cita (versión simple, se mantiene para no romper llamadas existentes)
  static Future<bool> crearCita(Map<String, dynamic> citaData) async {
    final resultado = await crearCitaConMensaje(citaData);
    return resultado.ok;
  }

  // 3.1 🟢 NUEVO: Crear cita devolviendo también el mensaje del backend
  // (por ejemplo "Esa hora ya no tiene cupos disponibles" cuando responde 409).
  static Future<({bool ok, String? mensaje})> crearCitaConMensaje(
      Map<String, dynamic> citaData) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(citaData),
    );

    final ok = response.statusCode == 201 || response.statusCode == 200;
    if (ok) return (ok: true, mensaje: null);

    String? mensaje;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['mensaje'] != null) {
        mensaje = body['mensaje'].toString();
      }
    } catch (_) {}

    return (ok: false, mensaje: mensaje);
  }

  // 3.2 🟢 NUEVO: Cupos por hora de un día. `fecha` en formato YYYY-MM-DD.
  // Usa GET /api/appointments/cupos?fecha=YYYY-MM-DD
  static Future<CuposDia> getCuposDelDia(String fecha) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appointments/cupos?fecha=$fecha'),
      headers: {
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar los cupos (Código: ${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final int limite = (body['limite'] as num?)?.toInt() ?? 5;
    final Map<int, int> ocupadasPorHora = {};

    for (final h in (body['horas'] as List? ?? [])) {
      ocupadasPorHora[(h['hora'] as num).toInt()] = (h['ocupadas'] as num).toInt();
    }

    return CuposDia(limite: limite, ocupadasPorHora: ocupadasPorHora);
  }

  // 4. Obtener todas las citas (Panel Admin) — sin filtrar por usuario
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
      final body = jsonDecode(response.body);
      return body is List ? body : [];
    } else {
      throw Exception('Error al cargar lavadas programadas (Código: ${response.statusCode})');
    }
  }

  // 5. Obtener las citas del usuario logueado (App Móvil Flutter)
  // Usa la ruta protegida GET /api/appointments/usuario/:usuarioId
  static Future<List<dynamic>> getCitasPorUsuario(String usuarioId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appointments/usuario/$usuarioId'),
      headers: {
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body is List ? body : [];
    } else {
      throw Exception('Error al cargar tus citas (Código: ${response.statusCode})');
    }
  }

  // 6. Obtener el historial de citas por estado completado
  static Future<List<dynamic>> getHistorialCitas() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appointments?estado=finalizada'),
      headers: {
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body is List ? body : [];
    } else {
      throw Exception('Error al cargar el historial (Código: ${response.statusCode})');
    }
  }

  // 7. Cambiar estado de una cita (usa los valores del enum del schema)
  static Future<bool> actualizarEstadoCita(String citaId, String nuevoEstado) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/appointments/estado/$citaId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'estado': nuevoEstado}),
    );

    return response.statusCode == 200;
  }
}