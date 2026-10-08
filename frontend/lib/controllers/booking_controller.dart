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

  /// Combina el día elegido con la hora del slot ('08:00 AM', '02:00 PM')
  /// y devuelve el instante en UTC, tomando la hora como hora de Colombia
  /// (UTC-5). Así el backend guarda la hora real de la cita y puede contar
  /// los cupos por hora sin depender de la zona horaria del celular.
  DateTime _combinarFechaYHora(DateTime fecha, String hora) {
    final partes = hora.trim().split(' ');
    final hm = partes[0].split(':');
    int h = int.parse(hm[0]);
    final int m = int.parse(hm[1]);
    final bool esPM = partes.length > 1 && partes[1].toUpperCase() == 'PM';

    if (esPM && h != 12) h += 12;
    if (!esPM && h == 12) h = 0;

    // Colombia = UTC-5  ->  hora UTC = hora local + 5
    return DateTime.utc(fecha.year, fecha.month, fecha.day, h + 5, m);
  }

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
    // 🟢 Ahora incluye la hora elegida (antes solo se enviaba el día a las 00:00)
    final fechaCitaIso =
        _combinarFechaYHora(selectedDate, selectedTime).toIso8601String();

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
      'tipoVehiculo': vehiculoSel['tipo'],
      'precio': servicioSel['precio'],
      'vehiculo': vehiculoSel['nombre'],
      'servicio': servicioSel['nombreBase'] ?? servicioSel['nombre'],
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