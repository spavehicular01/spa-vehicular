import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_required_dialog.dart';
import 'booking_screen.dart';
import '../services/appointment_service.dart';

class CalendarScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final String? token;

  const CalendarScreen({super.key, this.usuario, this.token});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Map<String, dynamic>> _horariosDisponibles = [
    {'hora': '08:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '09:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '10:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '11:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '02:00 PM', 'ocupado': false, 'servicio': ''},
    {'hora': '03:00 PM', 'ocupado': false, 'servicio': ''},
    {'hora': '04:00 PM', 'ocupado': false, 'servicio': ''},
    {'hora': '05:00 PM', 'ocupado': false, 'servicio': ''},
  ];

  @override
  void initState() {
    super.initState();
    _cargarCitasDelDia();
  }

  Future<void> _cargarCitasDelDia() async {
    setState(() => _isLoading = true);

    try {
      final fechaStr = _selectedDate.toIso8601String().split('T')[0];
      final citasBackend = await AppointmentService.obtenerCitasPorFecha(
        fechaStr,
        token: widget.token,
      );

      final listadoActualizado = [
        {'hora': '08:00 AM', 'ocupado': false, 'servicio': ''},
        {'hora': '09:00 AM', 'ocupado': false, 'servicio': ''},
        {'hora': '10:00 AM', 'ocupado': false, 'servicio': ''},
        {'hora': '11:00 AM', 'ocupado': false, 'servicio': ''},
        {'hora': '02:00 PM', 'ocupado': false, 'servicio': ''},
        {'hora': '03:00 PM', 'ocupado': false, 'servicio': ''},
        {'hora': '04:00 PM', 'ocupado': false, 'servicio': ''},
        {'hora': '05:00 PM', 'ocupado': false, 'servicio': ''},
      ];

      for (var cita in citasBackend) {
        final horaCita = cita['hora'];
        for (var slot in listadoActualizado) {
          if (slot['hora'] == horaCita) {
            slot['ocupado'] = true;
            slot['servicio'] = cita['servicio'] ?? 'Reservado';
          }
        }
      }

      if (mounted) {
        setState(() {
          _horariosDisponibles = listadoActualizado;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar citas del día: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _irAFormularioReserva(Map<String, dynamic> slot) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null ||
        token.trim().isEmpty ||
        token == 'null' ||
        widget.usuario == null) {
      if (!mounted) return;
      AuthRequiredDialog.show(context);
      return;
    }

    if (!mounted) return;

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          selectedDate: _selectedDate,
          selectedTime: slot['hora'],
          usuario: widget.usuario!,
          token: widget.token,
        ),
      ),
    );

    if (resultado != null && resultado is Map<String, dynamic>) {
      _cargarCitasDelDia();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Agenda tu Cita', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppTheme.azulElectrico,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animación suave de agua en el fondo
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

          Column(
            children: [
              // 1. Calendario
              Card(
                margin: const EdgeInsets.all(12.0),
                elevation: 2,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  onDateChanged: (newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                    _cargarCitasDelDia();
                  },
                ),
              ),

              // Leyenda Informativa adaptable
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cupos del día',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: isDark ? const Color(0xFF60A5FA) : AppTheme.azulElectrico,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.circle,
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ocupado',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Rejilla de horarios o Loader
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.azulElectrico),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _horariosDisponibles.length,
                        itemBuilder: (context, index) {
                          final slot = _horariosDisponibles[index];
                          final bool estaOcupado = slot['ocupado'];

                          final Color cardBg = estaOcupado
                              ? (isDark ? const Color(0xFF0F172A) : Colors.grey.shade200)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF));

                          final Color borderColor = estaOcupado
                              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade400)
                              : (isDark ? const Color(0xFF3B82F6) : AppTheme.azulElectrico);

                          final Color horaColor = estaOcupado
                              ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                              : (isDark ? Colors.white : const Color(0xFF0F172A));

                          final Color subtextColor = estaOcupado
                              ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                              : (isDark ? const Color(0xFF60A5FA) : AppTheme.azulElectrico);

                          return InkWell(
                            onTap: estaOcupado ? null : () => _irAFormularioReserva(slot),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slot['hora'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: horaColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    estaOcupado
                                        ? (slot['servicio'].isNotEmpty ? slot['servicio'] : 'Reservado')
                                        : 'Agendar cita',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtextColor,
                                      fontWeight: estaOcupado ? FontWeight.normal : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}