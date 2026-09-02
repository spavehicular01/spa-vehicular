import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

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

  // Lista de vehículos registrados (debería venir de MongoDB con su _id)
  final List<Map<String, String>> _misVehiculos = [
    {'id': '64b0f1a23c8e4d001234567a', 'nombre': 'Mazda 3 - ABC-123'},
    {'id': '64b0f1a23c8e4d001234567b', 'nombre': 'Toyota Hilux - XYZ-789'},
    {'id': '64b0f1a23c8e4d001234567c', 'nombre': 'Chevrolet Onix - FGH-456'},
  ];
  String? _vehiculoSeleccionadoId;

  // Lista de servicios registrados (debería venir de MongoDB con su _id)
  final List<Map<String, String>> _servicios = [
    {'id': '64b0f2a23c8e4d001234568a', 'nombre': 'Lavado Básico (30 min)'},
    {'id': '64b0f2a23c8e4d001234568b', 'nombre': 'Lavado Especial (45 min)'},
    {'id': '64b0f2a23c8e4d001234568c', 'nombre': 'Lavado General / Chasis (60 min)'},
    {'id': '64b0f2a23c8e4d001234568d', 'nombre': 'Polichado y Encerado (90 min)'},
    {'id': '64b0f2a23c8e4d001234568e', 'nombre': 'Coctel / Tapicería Profunda (120 min)'},
  ];
  String? _servicioSeleccionadoId;

  // Modalidad
  String _modalidad = 'Llevo el vehículo';
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
    _vehiculoSeleccionadoId = _misVehiculos.first['id'];
    _servicioSeleccionadoId = _servicios.first['id'];
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _confirmarReserva() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Formatear la fecha y hora seleccionada en ISO 8601
      final fechaCitaIso = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      ).toIso8601String();

      // Construcción del Payload normalizado para Node.js y Mongoose
      final datosCita = {
        'usuarioId': widget.usuario?['_id'] ?? widget.usuario?['id'],
        'vehiculoId': _vehiculoSeleccionadoId,
        'servicioId': _servicioSeleccionadoId,
        'vehiculo': _misVehiculos.firstWhere((v) => v['id'] == _vehiculoSeleccionadoId)['nombre'],
        'servicio': _servicios.firstWhere((s) => s['id'] == _servicioSeleccionadoId)['nombre'],
        'fechaHoraCita': fechaCitaIso,
        'hora': widget.selectedTime,
        'correo': widget.usuario?['correo'],
        'modalidad': _modalidad == 'A domicilio' ? 'a_domicilio' : 'en_spa',
        'direccion': _modalidad == 'A domicilio' ? _direccionController.text : null,
        'metodoPago': _metodoPago,
        'especificaciones': _notasController.text,
        'estado': 'Pendiente',
      };

      print('--> PAYLOAD ENVIADO AL BACKEND: $datosCita');
      print('--> TOKEN JWT ENVIADO: ${widget.token}');

      // Pasar datos y token JWT al servicio
      final respuesta = await AppointmentService.crearCita(datosCita, token: widget.token);

      print('--> RESPUESTA DEL SERVIDOR: $respuesta');

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (respuesta['success'] == true || respuesta['status'] == 201 || respuesta['status'] == 200) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta['message'] ?? respuesta['error'] ?? 'Error al agendar cita'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      print('--> EXCEPCIÓN AL AGENDAR: $e');
      print('--> STACKTRACE: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión o datos inválidos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              Card(
                color: Colors.teal.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color.fromARGB(255, 0, 34, 255)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: Color.fromARGB(255, 0, 34, 255), size: 36),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Hora del cupo: ${widget.selectedTime}',
                            style: const TextStyle(color: Color.fromARGB(255, 0, 30, 255), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Vehículo a lavar:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _vehiculoSeleccionadoId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: _misVehiculos.map((vehiculo) {
                  return DropdownMenuItem(
                    value: vehiculo['id'],
                    child: Text(vehiculo['nombre']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _vehiculoSeleccionadoId = val),
              ),
              const SizedBox(height: 20),

              const Text('Tipo de lavado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _servicioSeleccionadoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_car_wash),
                ),
                items: _servicios.map((serv) {
                  return DropdownMenuItem(
                    value: serv['id'],
                    child: Text(serv['nombre']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _servicioSeleccionadoId = val),
              ),
              const SizedBox(height: 20),

              const Text('¿Dónde realizamos el servicio?:', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                title: const Text('Llevo el vehículo al spa'),
                value: 'Llevo el vehículo',
                groupValue: _modalidad,
                activeColor: const Color.fromARGB(255, 0, 26, 255),
                onChanged: (val) => setState(() => _modalidad = val!),
              ),
              RadioListTile<String>(
                title: const Text('A domicilio'),
                value: 'A domicilio',
                groupValue: _modalidad,
                activeColor: const Color.fromARGB(255, 0, 26, 255),
                onChanged: (val) => setState(() => _modalidad = val!),
              ),

              if (_modalidad == 'A domicilio') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección de residencia / entrega',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (_modalidad == 'A domicilio' && (val == null || val.trim().isEmpty)) {
                      return 'Ingresa tu dirección para el domicilio';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _opcionesPago.map((metodo) {
                  return DropdownMenuItem(value: metodo, child: Text(metodo));
                }).toList(),
                onChanged: (val) => setState(() => _metodoPago = val!),
              ),
              const SizedBox(height: 20),

              const Text('Sugerencias o especificaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notasController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ej. Cuidado especial con el retrovisor derecho, manchas en el tapizado trasero...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _confirmarReserva,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirmar y Agendar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}