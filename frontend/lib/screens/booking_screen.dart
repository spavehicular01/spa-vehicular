import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class BookingScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final Map<String, dynamic> usuario;
  final String? token;

  const BookingScreen({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.usuario,
    this.token,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _misVehiculos = [
    'Mazda 3 - ABC-123',
    'Toyota Hilux - XYZ-789',
    'Chevrolet Onix - FGH-456',
  ];
  String? _vehiculoSeleccionado;

  final List<String> _servicios = [
    'Lavado Básico (30 min)',
    'Lavado Especial (45 min)',
    'Lavado General / Chasis (60 min)',
    'Polichado y Encerado (90 min)',
    'Coctel / Tapicería Profunda (120 min)',
  ];
  String? _servicioSeleccionado;

  // Modalidad: Taller vs Domicilio
  String _modalidad = 'Llevo el vehículo';
  final _direccionController = TextEditingController();

  String _metodoPago = 'Efectivo';
  final List<String> _opcionesPago = [
    'Efectivo',
    'Transferencia (Nequi / Daviplata)',
    'Tarjeta Débito / Crédito',
  ];

  // Sugerencias / Notas libres
  final _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vehiculoSeleccionado = _misVehiculos.first;
    _servicioSeleccionado = _servicios.first;
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

    // Preparar el cuerpo de los datos para la API
    final datosCita = {
      'usuarioId': widget.usuario['_id'] ?? widget.usuario['id'],
      'correo': widget.usuario['correo'],
      'hora': widget.selectedTime,
      'fechaHoraCita': widget.selectedDate.toIso8601String(),
      'servicio': _servicioSeleccionado,
      'vehiculo': _vehiculoSeleccionado,
      'modalidad': _modalidad,
      'direccion': _modalidad == 'A domicilio' ? _direccionController.text : null,
      'metodoPago': _metodoPago,
      'notas': _notasController.text,
      'estado': 'Pendiente',
    };

    // Llamada al backend Node.js
    final respuesta = await AppointmentService.crearCita(
      datosCita,
      token: widget.token,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (respuesta['success']) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Cita Confirmada! 🎉'),
          content: Text(
            'Tu servicio de "$_servicioSeleccionado" para el vehículo '
            '$_vehiculoSeleccionado ha sido programado para el '
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
                Navigator.pop(context, respuesta['cita'] ?? datosCita);
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['message'] ?? 'Error al agendar cita'),
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
                value: _vehiculoSeleccionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: _misVehiculos.map((vehiculo) {
                  return DropdownMenuItem(value: vehiculo, child: Text(vehiculo));
                }).toList(),
                onChanged: (val) => setState(() => _vehiculoSeleccionado = val),
              ),
              const SizedBox(height: 20),

              const Text('Tipo de lavado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _servicioSeleccionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_car_wash),
                ),
                items: _servicios.map((serv) {
                  return DropdownMenuItem(value: serv, child: Text(serv));
                }).toList(),
                onChanged: (val) => setState(() => _servicioSeleccionado = val),
              ),
              const SizedBox(height: 20),

              // 3. Modalidad
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

              // 5. Sugerencias / Notas Libres
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
