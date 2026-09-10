import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/appointment_service.dart';
import '../widgets/booking/modality_selector.dart';

class BookingController {
  final Map<String, dynamic>? usuario;
  final String? tokenInicial;

  String? authToken;

  BookingController({required this.usuario, required this.tokenInicial});

  /// Resuelve el token: usa el que llega por parámetro, o si no,
  /// intenta recuperarlo de SharedPreferences como respaldo.
  Future<void> resolverToken() async {
    if (tokenInicial == null || tokenInicial!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('token') ?? '';
    } else {
      authToken = tokenInicial;
    }

    debugPrint('--> USUARIO RECIBIDO EN BookingScreen: $usuario');
    debugPrint('--> usuarioId resuelto: ${usuario?['_id'] ?? usuario?['id']}');
  }

  String? get usuarioId => usuario?['_id'] ?? usuario?['id'];

  Map<String, dynamic> construirPayload({
    required DateTime selectedDate,
    required String selectedTime,
    required String? vehiculoSeleccionadoId,
    required String? servicioSeleccionadoId,
    required List<Map<String, String>> misVehiculos,
    required List<Map<String, dynamic>> servicios,
    required String modalidad,
    required String direccion,
    required String metodoPago,
    required String notas,
  }) {
    final fechaCitaIso = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).toIso8601String();

    final vehiculoSel = misVehiculos.firstWhere(
      (v) => v['id'] == vehiculoSeleccionadoId,
      orElse: () => {'id': '', 'nombre': 'Vehículo Seleccionado'},
    );

    final servicioSel = servicios.firstWhere(
      (s) => s['id'] == servicioSeleccionadoId,
      orElse: () => {'id': '', 'nombre': 'Servicio Seleccionado', 'minutos': 30},
    );

    final bool esDomicilio = modalidad == ModalitySelector.valorDomicilio;

    return {
      'usuarioId': usuarioId,
      'vehiculoId': vehiculoSeleccionadoId,
      'servicioId': servicioSeleccionadoId,
      'vehiculo': vehiculoSel['nombre'],
      'servicio': servicioSel['nombre'],
      'tiempoEstimadoMinutos': servicioSel['minutos'],
      'fechaHoraCita': fechaCitaIso,
      'hora': selectedTime,
      'correo': usuario?['correo'],
      'modalidad': esDomicilio ? 'domicilio' : 'presencial',
      'direccion': esDomicilio ? direccion.trim() : null,
      'metodoPago': metodoPago,
      'especificaciones': notas.trim(),
      // 'estado' se omite intencionalmente: el schema ya tiene default: 'pendiente'
    };
  }

  Future<Map<String, dynamic>> confirmarReserva(Map<String, dynamic> datosCita) async {
    debugPrint('--> PAYLOAD ENVIADO AL BACKEND: $datosCita');
    debugPrint('--> TOKEN JWT ENVIADO: $authToken');

    final respuesta = await AppointmentService.crearCita(datosCita, token: authToken);

    debugPrint('--> RESPUESTA DEL SERVIDOR: $respuesta');
    return respuesta;
  }

  bool fueExitosa(Map<String, dynamic> respuesta) {
    return respuesta['success'] == true ||
        respuesta['status'] == 201 ||
        respuesta['status'] == 200;
  }
}