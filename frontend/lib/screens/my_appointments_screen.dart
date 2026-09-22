import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import 'booking_screen.dart';

class SelectDateTimeScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final String? token;

  const SelectDateTimeScreen({
    super.key,
    required this.usuario,
    this.token,
  });

  @override
  State<SelectDateTimeScreen> createState() => _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends State<SelectDateTimeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  // Horarios disponibles simulados
  final List<String> _horariosDisponibles = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Seleccionar Cita', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.azulElectrico,
        foregroundColor: Colors.white,
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

          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selector de Fecha
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.azulElectrico),
                          const SizedBox(width: 8),
                          Text(
                            'Fecha del Servicio',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                            _selectedTime = null; // Reiniciar hora al cambiar día
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Selector de Horarios
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, color: AppTheme.azulElectrico),
                          const SizedBox(width: 8),
                          Text(
                            'Horarios Disponibles',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _horariosDisponibles.map((hora) {
                          final isSelected = _selectedTime == hora;
                          return ChoiceChip(
                            label: Text(hora),
                            selected: isSelected,
                            selectedColor: AppTheme.azulElectrico,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? AppTheme.azulElectrico : borderColor,
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedTime = selected ? hora : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Continuar
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedTime == null
                        ? null
                        : () async {
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(
                                  selectedDate: _selectedDate,
                                  selectedTime: _selectedTime!,
                                  usuario: widget.usuario,
                                  token: widget.token,
                                ),
                              ),
                            );

                            if (resultado != null && context.mounted) {
                              Navigator.pop(context, resultado);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.azulElectrico,
                      disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continuar a Detalles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}