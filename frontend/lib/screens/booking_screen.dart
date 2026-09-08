import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/appointment_service.dart';

import '../widgets/booking/appointment_summary_card.dart';
import '../widgets/booking/vehicle_selector.dart';
import '../widgets/booking/service_selector.dart';
import '../widgets/booking/modality_selector.dart';
import '../widgets/booking/payment_method_selector.dart';
import '../widgets/booking/notes_field.dart';
import '../widgets/booking/confirm_booking_button.dart';

class BookingScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final Map<String, dynamic>? usuario;
  final String? token;

  const BookingScreen({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    this.usuario,
    this.token,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _authToken;

  // Lista de vehículos registrados (dinámicos / fallback)
  final List<Map<String, String>> _misVehiculos = [
    {'id': '64b0f1a23c8e4d001234567a', 'nombre': 'Mazda 3 - ABC-123'},
    {'id': '64b0f1a23c8e4d001234567b', 'nombre': 'Toyota Hilux - XYZ-789'},
    {'id': '64b0f1a23c8e4d001234567c', 'nombre': 'Chevrolet Onix - FGH-456'},
  ];
  String? _vehiculoSeleccionadoId;

  // Lista de servicios registrados (dinámicos / fallback)
  // 'minutos' es obligatorio porque el backend requiere tiempoEstimadoMinutos
  final List<Map<String, dynamic>> _servicios = [
    {'id': '64b0f2a23c8e4d001234568a', 'nombre': 'Lavado Básico (30 min)', 'minutos': 30},
    {'id': '64b0f2a23c8e4d001234568b', 'nombre': 'Lavado Especial (45 min)', 'minutos': 45},
    {'id': '64b0f2a23c8e4d001234568c', 'nombre': 'Lavado General / Chasis (60 min)', 'minutos': 60},
    {'id': '64b0f2a23c8e4d001234568d', 'nombre': 'Polichado y Encerado (90 min)', 'minutos': 90},
    {'id': '64b0f2a23c8e4d001234568e', 'nombre': 'Coctel / Tapicería Profunda (120 min)', 'minutos': 120},
  ];
  String? _servicioSeleccionadoId;

  // Modalidad (valor mostrado en UI, se traduce al enum del backend al enviar)
  String _modalidad = ModalitySelector.valorSpa;
  final _direccionController = TextEditingController();

  // Pago
  String _metodoPago = 'Efectivo';
  final List<String> _opcionesPago = [
    'Efectivo',
    'Transferencia (Nequi / Daviplata)',
    'Tarjeta Débito / Crédito',
  ];

  final _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    // Si no se pasó el token por parámetro, se recupera de SharedPreferences
    if (widget.token == null || widget.token!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token') ?? '';
    } else {
      _authToken = widget.token;
    }

    // 🔍 DEBUG: confirma si el mapa 'usuario' llegó correctamente a esta pantalla
    debugPrint('--> USUARIO RECIBIDO EN BookingScreen: ${widget.usuario}');
    debugPrint('--> usuarioId resuelto: ${widget.usuario?['_id'] ?? widget.usuario?['id']}');

    if (_misVehiculos.isNotEmpty) {
      _vehiculoSeleccionadoId = _misVehiculos.first['id'];
    }
    if (_servicios.isNotEmpty) {
      _servicioSeleccionadoId = _servicios.first['id'] as String;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _confirmarReserva() async {
    if (!_formKey.currentState!.validate()) return;

    final usuarioId = widget.usuario?['_id'] ?? widget.usuario?['id'];

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró tu sesión. Vuelve a iniciar sesión e intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fechaCitaIso = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      ).toIso8601String();

      final vehiculoSel = _misVehiculos.firstWhere(
        (v) => v['id'] == _vehiculoSeleccionadoId,
        orElse: () => {'id': '', 'nombre': 'Vehículo Seleccionado'},
      );

      final servicioSel = _servicios.firstWhere(
        (s) => s['id'] == _servicioSeleccionadoId,
        orElse: () => {'id': '', 'nombre': 'Servicio Seleccionado', 'minutos': 30},
      );

      final bool esDomicilio = _modalidad == ModalitySelector.valorDomicilio;

      final datosCita = {
        'usuarioId': usuarioId,
        'vehiculoId': _vehiculoSeleccionadoId,
        'servicioId': _servicioSeleccionadoId,
        'vehiculo': vehiculoSel['nombre'],
        'servicio': servicioSel['nombre'],
        'tiempoEstimadoMinutos': servicioSel['minutos'],
        'fechaHoraCita': fechaCitaIso,
        'hora': widget.selectedTime,
        'correo': widget.usuario?['correo'],
        'modalidad': esDomicilio ? 'domicilio' : 'presencial',
        'direccion': esDomicilio ? _direccionController.text.trim() : null,
        'metodoPago': _metodoPago,
        'especificaciones': _notasController.text.trim(),
        // 'estado' se omite intencionalmente: el schema ya tiene default: 'pendiente'
      };

      debugPrint('--> PAYLOAD ENVIADO AL BACKEND: $datosCita');
      debugPrint('--> TOKEN JWT ENVIADO: $_authToken');

      final respuesta = await AppointmentService.crearCita(datosCita, token: _authToken);

      debugPrint('--> RESPUESTA DEL SERVIDOR: $respuesta');

      setState(() => _isLoading = false);

      if (!mounted) return;

      final bool exito = respuesta['success'] == true ||
          respuesta['status'] == 201 ||
          respuesta['status'] == 200;

      if (exito) {
        _mostrarDialogoExito();
      } else {
        final mensajeError = respuesta['message'] ??
            respuesta['error'] ??
            'Error al agendar cita. Verifica los datos.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
        );
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      debugPrint('--> EXCEPCIÓN AL AGENDAR: $e');
      debugPrint('--> STACKTRACE: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión o datos inválidos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Cita Confirmada! 🎉'),
        content: Text(
          'Tu servicio ha sido programado con éxito para el '
          '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year} '
          'a las ${widget.selectedTime}.\n\n'
          'Modalidad: $_modalidad\n'
          'Pago: $_metodoPago',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 32, 150),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Cita'),
        backgroundColor: const Color.fromARGB(255, 0, 55, 255),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppointmentSummaryCard(
                selectedDate: widget.selectedDate,
                selectedTime: widget.selectedTime,
              ),
              const SizedBox(height: 20),

              VehicleSelector(
                vehiculos: _misVehiculos,
                vehiculoSeleccionadoId: _vehiculoSeleccionadoId,
                onChanged: (val) => setState(() => _vehiculoSeleccionadoId = val),
              ),
              const SizedBox(height: 20),

              ServiceSelector(
                servicios: _servicios,
                servicioSeleccionadoId: _servicioSeleccionadoId,
                onChanged: (val) => setState(() => _servicioSeleccionadoId = val),
              ),
              const SizedBox(height: 20),

              ModalitySelector(
                modalidad: _modalidad,
                onChanged: (val) => setState(() => _modalidad = val!),
                direccionController: _direccionController,
              ),
              const SizedBox(height: 20),

              PaymentMethodSelector(
                metodoPago: _metodoPago,
                opciones: _opcionesPago,
                onChanged: (val) => setState(() => _metodoPago = val!),
              ),
              const SizedBox(height: 20),

              NotesField(controller: _notasController),
              const SizedBox(height: 24),

              ConfirmBookingButton(
                isLoading: _isLoading,
                onPressed: _confirmarReserva,
              ),
            ],
          ),
        ),
      ),
    );
  }
}