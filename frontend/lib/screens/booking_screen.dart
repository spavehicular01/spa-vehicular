import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  // Azul eléctrico de marca (#0033FF) y azul marino profundo
  static const Color azulBrand = Color(0xFF0033FF); 
  static const Color azulOscuro = Color(0xFF001A80);

  late List<String> _misVehiculos;
  String? _vehiculoSeleccionado;

  final List<String> _servicios = [
    'Lavado Básico (30 min)',
    'Lavado Especial (45 min)',
    'Lavado General / Chasis (60 min)',
    'Polichado y Encerado (90 min)',
    'Coctel / Tapicería Profunda (120 min)',
  ];
  String? _servicioSeleccionado;

  String _modalidad = 'Llevo el vehículo';
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
    _cargarVehiculosUsuario();
    _servicioSeleccionado = _servicios.first;
  }

  void _cargarVehiculosUsuario() {
    final List<dynamic>? rawVehiculos = widget.usuario['vehiculos'];
    _misVehiculos = [];

    if (rawVehiculos != null && rawVehiculos.isNotEmpty) {
      for (var v in rawVehiculos) {
        if (v is Map) {
          final marca = v['marca'] ?? '';
          final referencia = v['referencia'] ?? v['modelo'] ?? '';
          final placa = v['placa'] ?? '';
          if (placa.toString().isNotEmpty) {
            _misVehiculos.add('$marca $referencia - $placa'.trim());
          }
        } else if (v is String) {
          _misVehiculos.add(v);
        }
      }
    }

    if (_misVehiculos.isEmpty) {
      _misVehiculos = ['Sin vehículo registrado'];
    }

    _vehiculoSeleccionado = _misVehiculos.first;
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

    final datosCita = {
      'usuarioId': widget.usuario['_id'] ?? widget.usuario['id'],
      'correo': widget.usuario['correo'] ?? widget.usuario['email'],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 110,
                child: Lottie.asset(
                  'assets/animations/water_waves.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: azulBrand,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Cita Agendada!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu servicio de "$_servicioSeleccionado" ha sido programado con éxito.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, respuesta['cita'] ?? datosCita);
                  },
                  child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['message'] ?? 'Error al agendar cita'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Detalles de la Cita', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : azulBrand,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animación suave de fondo
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.04 : 0.06,
              child: Lottie.asset(
                'assets/animations/water_waves.json',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Azul Principal (Fecha y Hora)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [azulBrand, azulOscuro],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: azulBrand.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.event_available, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hora del cupo: ${widget.selectedTime}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFFE0E7FF), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta Formulario Estilizada
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Vehículo a lavar:', textColor),
                        DropdownButtonFormField<String>(
                          value: _vehiculoSeleccionado,
                          dropdownColor: cardBg,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: _buildInputDecoration(inputBg, borderColor, Icons.directions_car),
                          items: _misVehiculos.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (val) => setState(() => _vehiculoSeleccionado = val),
                        ),
                        const SizedBox(height: 18),

                        _buildLabel('Tipo de lavado:', textColor),
                        DropdownButtonFormField<String>(
                          value: _servicioSeleccionado,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: _buildInputDecoration(inputBg, borderColor, Icons.local_car_wash),
                          items: _servicios.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _servicioSeleccionado = val),
                        ),
                        const SizedBox(height: 18),

                        _buildLabel('¿Dónde realizamos el servicio?:', textColor),
                        Row(
                          children: [
                            Expanded(child: _buildChoiceChip('Llevo el vehículo', 'En Spa', Icons.store, inputBg, borderColor, textColor)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildChoiceChip('A domicilio', 'Domicilio', Icons.local_shipping, inputBg, borderColor, textColor)),
                          ],
                        ),

                        if (_modalidad == 'A domicilio') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _direccionController,
                            style: TextStyle(color: textColor),
                            decoration: _buildInputDecoration(inputBg, borderColor, Icons.home, hint: 'Dirección de residencia / entrega'),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa tu dirección' : null,
                          ),
                        ],
                        const SizedBox(height: 18),

                        _buildLabel('Método de Pago:', textColor),
                        DropdownButtonFormField<String>(
                          value: _metodoPago,
                          dropdownColor: cardBg,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: _buildInputDecoration(inputBg, borderColor, Icons.payment),
                          items: _opcionesPago.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setState(() => _metodoPago = val!),
                        ),
                        const SizedBox(height: 18),

                        _buildLabel('Sugerencias o especificaciones:', textColor),
                        TextFormField(
                          controller: _notasController,
                          maxLength: 500,
                          maxLines: 3,
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(inputBg, borderColor, Icons.edit_note, hint: 'Cuidado especial con retrovisores, manchas en tapizado...'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Azul Agendar Cita
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmarReserva,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulBrand,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Confirmar y Agendar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
    );
  }

  InputDecoration _buildInputDecoration(Color bg, Color border, IconData icon, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icon, color: azulBrand),
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulBrand, width: 2),
      ),
    );
  }

  Widget _buildChoiceChip(String value, String title, IconData icon, Color bg, Color border, Color textColor) {
    final bool isSelected = _modalidad == value;
    return GestureDetector(
      onTap: () => setState(() => _modalidad = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? azulBrand.withOpacity(0.12) : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? azulBrand : border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? azulBrand : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? azulBrand : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}