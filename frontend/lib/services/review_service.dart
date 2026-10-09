import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Resultado de GET /api/reviews
class ResumenOpiniones {
  final double promedio;
  final int total;
  final List<Map<String, dynamic>> opiniones;

  const ResumenOpiniones({
    this.promedio = 0,
    this.total = 0,
    this.opiniones = const [],
  });
}

class ReviewService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Opiniones públicas (no requiere sesión).
  static Future<ResumenOpiniones> obtenerOpiniones() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/reviews'));
      if (res.statusCode != 200) return const ResumenOpiniones();

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final lista = (data['opiniones'] as List? ?? [])
          .whereType<Map>()
          .map((o) => Map<String, dynamic>.from(o))
          .toList();

      return ResumenOpiniones(
        promedio: (data['promedio'] as num?)?.toDouble() ?? 0,
        total: (data['total'] as num?)?.toInt() ?? lista.length,
        opiniones: lista,
      );
    } catch (e) {
      debugPrint('ERROR OBTENER OPINIONES: $e');
      return const ResumenOpiniones();
    }
  }

  /// La opinión del usuario con sesión, o null si aún no ha opinado.
  static Future<Map<String, dynamic>?> obtenerMiOpinion() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/mia'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final op = data['opinion'];
      return op is Map ? Map<String, dynamic>.from(op) : null;
    } catch (e) {
      debugPrint('ERROR MI OPINION: $e');
      return null;
    }
  }

  /// Crea o actualiza la opinión. Devuelve null si salió bien,
  /// o el mensaje de error para mostrarlo al usuario.
  static Future<String?> guardarOpinion({
    required int calificacion,
    required String comentario,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews'),
        headers: await _headers(),
        body: jsonEncode({
          'calificacion': calificacion,
          'comentario': comentario.trim(),
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) return null;

      final data = jsonDecode(res.body);
      return (data is Map ? data['mensaje'] : null)?.toString() ??
          'No se pudo guardar tu opinión';
    } catch (e) {
      debugPrint('ERROR GUARDAR OPINION: $e');
      return 'Error de conexión con el servidor';
    }
  }
}