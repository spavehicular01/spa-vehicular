import 'package:flutter/material.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_static_data.dart';
import '../theme/app_theme.dart'; // Importación agregada

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

  late final BookingController _controller;

  String? _vehiculoSeleccionadoId;
  String? _servicioSeleccionadoId;

  String _modalidad = ModalitySelector.valorSpa;
  final _direccionController = TextEditingController();

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
    _controller = BookingController(usuario: widget.usuario, tokenInicial: widget.token);
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await _controller.resolverToken();

    if (BookingStaticData.misVehiculos.isNotEmpty) {
      _vehiculoSeleccionadoId = BookingStaticData.misVehiculos.first['id'];
    }
    if (BookingStaticData.servicios.isNotEmpty) {
      _servicioSeleccionadoId = BookingStaticData.servicios.first['id'] as String;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _confirmarReserva() async {
    if (!_formKey.currentState!.validate()) return;

    if (_controller.usuarioId == null) {
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
      final datosCita = _controller.construirPayload(
        selectedDate: widget.selectedDate,
        selectedTime: widget.selectedTime,
        vehiculoSeleccionadoId: _vehiculoSeleccionadoId,
        servicioSeleccionadoId: _servicioSeleccionadoId,
        misVehiculos: BookingStaticData.misVehiculos,
        servicios: BookingStaticData.servicios,
        modalidad: _modalidad,
        direccion: _direccionController.text,
        metodoPago: _metodoPago,
        notas: _notasController.text,
      );

      final respuesta = await _controller.confirmarReserva(datosCita);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (_controller.fueExitosa(respuesta)) {
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
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('--> EXCEPCIÓN AL AGENDAR: $e');
      debugPrint('--> STACKTRACE: $stackTrace');

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Detalles de la Cita', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppTheme.azulElectrico,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
                vehiculos: BookingStaticData.misVehiculos,
                vehiculoSeleccionadoId: _vehiculoSeleccionadoId,
                onChanged: (val) => setState(() => _vehiculoSeleccionadoId = val),
              ),
              const SizedBox(height: 20),

              ServiceSelector(
                servicios: BookingStaticData.servicios,
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