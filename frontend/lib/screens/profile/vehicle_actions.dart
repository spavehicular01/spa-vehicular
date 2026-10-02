import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_service.dart';

/// Trae los vehículos del usuario desde el backend (fuente de verdad).
/// Devuelve null si no hay sesión guardada.
Future<List<Map<String, String>>?> cargarVehiculosUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  final token = prefs.getString('token');

  if (userId == null || userId.isEmpty) return null;

  final raw = await VehicleService.obtenerVehiculos(userId, token: token);

  // Todo se convierte a Map<String, String> (incluye '_id' y 'tipoVehiculo').
  return raw.whereType<Map>().map<Map<String, String>>((v) {
    return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
  }).toList();
}

/// Elimina un vehículo en el backend. Devuelve true si se eliminó.
Future<bool> eliminarVehiculoUsuario(Map<String, String> car) async {
  final id = car['_id'] ?? car['id'] ?? '';
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return VehicleService.eliminarVehiculo(id, token: token);
}