import 'package:flutter/material.dart';
import '../controllers/booking_controller.dart';
import '../services/vehicle_service.dart';
import '../services/wash_service.dart';
import '../models/vehicle_types.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
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

  /// Servicio que el cliente ya eligió en la pantalla de servicios (opcional).
  /// Si viene, queda preseleccionado en "Tipo de lavado".
  final String? servicioInicialId;

  const BookingScreen({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    this.usuario,
    this.token,
    this.servicioInicialId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _cargandoDatos = true;
  String? _errorCarga;

  late final BookingController _controller;

  List<Map<String, String>> _vehiculos = [];
  List<Map<String, dynamic>> _servicios = [];

  String? _vehiculoSeleccionadoId;
  String? _servicioSeleccionadoId;

  String _modalidad = ModalitySelector.valorSpa;
  final _direccionController = TextEditingController();

  // Método con el que el cliente PREVÉ pagar al recoger el vehículo
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
          'tipo': (v['tipoVehiculo'] ?? '').toString(),
        };
      }).toList();

      final serviciosReales = await WashApiService.getLavados();

      final serviciosMapeados = serviciosReales.map<Map<String, dynamic>>((s) {
        return {
          'id': s.id,
          'nombre': s.nombre,
          'minutos': s.duracionMinutos,
          'nombreBase': s.nombre,
          'precios': <String, double>{
            for (final p in s.precios)
              if (p.precio > 0) p.tipoVehiculo: p.precio,
          },
        };
      }).toList();

      if (!mounted) return;

      // Si el cliente ya eligió un servicio en la pantalla de servicios, queda
      // preseleccionado. Además se escoge el primer vehículo compatible con ese
      // servicio (si hay alguno) para que arranque en una combinación válida.
      String? vehiculoInicial =
          vehiculosMapeados.isNotEmpty ? vehiculosMapeados.first['id'] : null;
      String? servicioInicial;
      final idElegido = widget.servicioInicialId;
      if (idElegido != null) {
        final coincidencias =
            serviciosMapeados.where((s) => s['id'] == idElegido).toList();
        if (coincidencias.isNotEmpty) {
          servicioInicial = idElegido;
          final precios = coincidencias.first['precios'] as Map<String, double>;
          final compatibles =
              vehiculosMapeados.where((v) => precios.containsKey(v['tipo'])).toList();
          if (compatibles.isNotEmpty) vehiculoInicial = compatibles.first['id'];
        }
      }

      // Si no venía un servicio elegido, se parte del primero que aplique al
      // vehículo inicial. Esto se hace UNA sola vez, al cargar la pantalla.
      if (servicioInicial == null && serviciosMapeados.isNotEmpty) {
        String tipoInicial = '';
        for (final v in vehiculosMapeados) {
          if (v['id'] == vehiculoInicial) tipoInicial = v['tipo'] ?? '';
        }
        final aplican = serviciosMapeados
            .where((s) => (s['precios'] as Map<String, double>).containsKey(tipoInicial))
            .toList();
        servicioInicial =
            (aplican.isNotEmpty ? aplican.first : serviciosMapeados.first)['id'] as String?;
      }

      setState(() {
        _vehiculos = vehiculosMapeados;
        _servicios = serviciosMapeados;
        _vehiculoSeleccionadoId = vehiculoInicial;
        _servicioSeleccionadoId = servicioInicial;
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

  /// Tipo del vehículo elegido (por ejemplo 'automovil'); vacío si no hay uno.
  String get _tipoVehiculoSeleccionado {
    for (final v in _vehiculos) {
      if (v['id'] == _vehiculoSeleccionadoId) return v['tipo'] ?? '';
    }
    return '';
  }

  /// Servicio elegido (mapa original, con la tabla de precios) o null.
  Map<String, dynamic>? get _servicioSeleccionado {
    for (final s in _servicios) {
      if (s['id'] == _servicioSeleccionadoId) return s;
    }
    return null;
  }

  /// Nombre del vehículo elegido, para mostrarlo en los avisos.
  String get _nombreVehiculoSeleccionado {
    for (final v in _vehiculos) {
      if (v['id'] == _vehiculoSeleccionadoId) return v['nombre'] ?? '';
    }
    return '';
  }

  /// ¿El servicio tiene precio para ese tipo de vehículo?
  bool _servicioAplicaATipo(Map<String, dynamic> servicio, String tipo) {
    final precios = servicio['precios'] as Map<String, double>;
    return precios.containsKey(tipo);
  }

  /// La combinación vehículo + servicio es válida solo si el servicio
  /// tiene precio para el tipo del vehículo elegido.
  bool get _combinacionValida {
    final servicio = _servicioSeleccionado;
    if (servicio == null || _vehiculoSeleccionadoId == null) return false;
    return _servicioAplicaATipo(servicio, _tipoVehiculoSeleccionado);
  }

  /// TODOS los servicios, siempre. Nunca se quitan de la lista (eso era lo que
  /// hacía que el servicio elegido cambiara solo). Si el servicio no aplica al
  /// vehículo actual, se marca como "No aplica" en vez de desaparecer.
  List<Map<String, dynamic>> get _serviciosParaSelector {
    final tipo = _tipoVehiculoSeleccionado;
    return _servicios.map<Map<String, dynamic>>((s) {
      final precios = s['precios'] as Map<String, double>;
      final precio = precios[tipo];
      if (precio == null) {
        return {
          ...s,
          'precio': 0.0,
          'aplica': false,
          'nombre': '${s['nombre']} (No aplica)',
        };
      }
      return {
        ...s,
        'precio': precio,
        'aplica': true,
        'nombre': '${s['nombre']} - ${formatearPesos(precio)}',
      };
    }).toList();
  }

  /// Vehículos con la marca "(No aplica)" cuando el servicio elegido no tiene
  /// precio para su tipo. El id no cambia, así la selección nunca se pierde.
  List<Map<String, String>> get _vehiculosParaSelector {
    final servicio = _servicioSeleccionado;
    return _vehiculos.map<Map<String, String>>((v) {
      final aplica = servicio == null || _servicioAplicaATipo(servicio, v['tipo'] ?? '');
      return {
        ...v,
        'aplica': aplica ? 'true' : 'false',
        'nombre': aplica ? (v['nombre'] ?? '') : '${v['nombre']} (No aplica)',
      };
    }).toList();
  }

  void _alCambiarVehiculo(String? id) {
    // Solo cambia el vehículo. El servicio elegido se respeta siempre.
    setState(() => _vehiculoSeleccionadoId = id);
  }

  void _alCambiarServicio(String? id) {
    // Solo cambia el servicio. El vehículo elegido se respeta siempre.
    setState(() => _servicioSeleccionadoId = id);
  }

  Widget _avisoCombinacionInvalida() {
    final servicio = _servicioSeleccionado;
    final nombreServicio = (servicio?['nombreBase'] ?? 'Este servicio').toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$nombreServicio" no aplica para $_nombreVehiculoSeleccionado '
              '(${etiquetaTipoVehiculo(_tipoVehiculoSeleccionado)}). '
              'Elige otro vehículo u otro servicio.',
              style: AppTextStyles.body.copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmarReserva() async {
    if (!_formKey.currentState!.validate()) return;

    if (_controller.usuarioId == null) {
      _mostrarError('No se encontró tu sesión. Vuelve a iniciar sesión e intenta de nuevo.');
      return;
    }

    if (_vehiculoSeleccionadoId == null || _servicioSeleccionadoId == null) {
      _mostrarError('Selecciona un vehículo y un servicio antes de continuar.');
      return;
    }

    // Bloquea la reserva si el servicio no aplica al tipo de vehículo elegido.
    if (!_combinacionValida) {
      _mostrarError(
        'Ese servicio no aplica para el vehículo elegido. Elige otro vehículo u otro servicio.',
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
        misVehiculos: _vehiculos,
        servicios: _serviciosParaSelector,
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
        // El backend responde los errores con la clave 'mensaje'
        // (por ejemplo, cuando la hora ya no tiene cupos).
        final mensajeError = respuesta['mensaje'] ??
            respuesta['message'] ??
            respuesta['error'] ??
            'Error al agendar cita. Verifica los datos.';
        _mostrarError(mensajeError.toString());
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('--> EXCEPCIÓN AL AGENDAR: $e');
      debugPrint('--> STACKTRACE: $stackTrace');

      if (!mounted) return;
      _mostrarError('Error de conexión o datos inválidos: $e');
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Cita Confirmada! 🎉', style: AppTextStyles.h2),
        content: Text(
          'Tu servicio ha sido programado con éxito para el '
          '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year} '
          'a las ${widget.selectedTime}.\n\n'
          'Modalidad: $_modalidad\n'
          'Pago al recoger tu vehículo: $_metodoPago',
          style: AppTextStyles.body,
        ),
        actions: [
          // Toma el estilo cian/navy del elevatedButtonTheme
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _mensajeCentrado(String texto, {Color? color}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sin colores manuales: usa appBarTheme (navy, centrado, blanco)
      appBar: AppBar(
        title: const Text('Detalles de la Cita'),
      ),
      body: _cargandoDatos
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _errorCarga != null
              ? _mensajeCentrado(_errorCarga!, color: Colors.redAccent)
              : _vehiculos.isEmpty
                  ? _mensajeCentrado(
                      'No tienes vehículos registrados. Agrega uno antes de agendar una cita.',
                    )
                  : _servicios.isEmpty
                      ? _mensajeCentrado('Aún no hay servicios de lavado disponibles.')
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
                                  vehiculos: _vehiculosParaSelector,
                                  vehiculoSeleccionadoId: _vehiculoSeleccionadoId,
                                  onChanged: _alCambiarVehiculo,
                                ),
                                const SizedBox(height: 20),

                                ServiceSelector(
                                  // Se recrea al cambiar de vehículo para que los
                                  // precios de la lista se refresquen, pero la
                                  // selección (servicioSeleccionadoId) no cambia.
                                  key: ValueKey('serv-$_vehiculoSeleccionadoId'),
                                  servicios: _serviciosParaSelector,
                                  servicioSeleccionadoId: _servicioSeleccionadoId,
                                  onChanged: _alCambiarServicio,
                                ),

                                if (!_combinacionValida) ...[
                                  const SizedBox(height: 12),
                                  _avisoCombinacionInvalida(),
                                ],
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
                                  // Si la combinación no es válida, _confirmarReserva
                                  // muestra el aviso y no envía nada.
                                  onPressed: _confirmarReserva,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
    );
  }
}