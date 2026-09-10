import 'package:flutter/material.dart';
import '../controllers/booking_controller.dart';
import '../services/vehicle_service.dart';
import '../services/wash_service.dart';

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
  bool _cargandoDatos = true; // 🟢 NUEVO: loading de vehículos/servicios reales
  String? _errorCarga; // 🟢 NUEVO: mensaje si algo falla al cargar

  late final BookingController _controller;

  // 🟢 NUEVO: reemplazan a BookingStaticData, se llenan con datos reales
  List<Map<String, String>> _vehiculos = [];
  List<Map<String, dynamic>> _servicios = [];

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

    final usuarioId = _controller.usuarioId;

    if (usuarioId == null || usuarioId.isEmpty) {
      setState(() {
        _errorCarga = 'No se encontró tu sesión. Vuelve a iniciar sesión e intenta de nuevo.';
        _cargandoDatos = false;
      });
      return;
    }

    try {
      // 🟢 Vehículos reales del usuario logueado
      final vehiculosRaw = await VehicleService.obtenerVehiculos(
        usuarioId,
        token: _controller.authToken,
      );

      final vehiculosMapeados = vehiculosRaw.map<Map<String, String>>((v) {
        final id = (v['_id'] ?? v['id'] ?? '').toString();
        final marca = (v['marca'] ?? '').toString();
        final referencia = (v['referencia'] ?? '').toString();
        final placa = (v['placa'] ?? '').toString();
        final nombre = [marca, referencia].where((s) => s.isNotEmpty).join(' ');
        return {
          'id': id,
          'nombre': placa.isNotEmpty ? '$nombre - $placa' : nombre,
        };
      }).toList();

      // 🟢 Servicios reales (los mismos que en "Servicios de Lavado")
      final serviciosReales = await WashApiService.getLavados();

      final serviciosMapeados = serviciosReales.map<Map<String, dynamic>>((s) {
        return {
          'id': s.id,
          'nombre': '${s.nombre} (${s.duracionMinutos} min)',
          'minutos': s.duracionMinutos,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _vehiculos = vehiculosMapeados;
        _servicios = serviciosMapeados;
        _vehiculoSeleccionadoId = vehiculosMapeados.isNotEmpty ? vehiculosMapeados.first['id'] : null;
        _servicioSeleccionadoId = serviciosMapeados.isNotEmpty ? serviciosMapeados.first['id'] as String? : null;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = 'No se pudieron cargar tus vehículos o los servicios disponibles.';
        _cargandoDatos = false;
      });
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

    if (_vehiculoSeleccionadoId == null || _servicioSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un vehículo y un servicio antes de continuar.'),
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
        misVehiculos: _vehiculos, // 🟢 datos reales
        servicios: _servicios, // 🟢 datos reales
        modalidad: _modalidad,
        direccion: _direccionController.text,
        metodoPago: _metodoPago,
        notas: _notasController.text,
      );

      final respuesta = await _controller.confirmarReserva(datosCita);

      setState(() => _isLoading = false);

      if (!mounted) return;

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
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorCarga!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _vehiculos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No tienes vehículos registrados. Agrega uno antes de agendar una cita.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _servicios.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Aún no hay servicios de lavado disponibles.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
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
                                  vehiculos: _vehiculos,
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