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
  // Fecha de "hoy" normalizada (sin horas/minutos), calculada una sola vez
  final DateTime _hoy = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _selectedDate = _hoy;
  String? _selectedTime;

  // Horarios disponibles simulados
  final List<String> _horariosDisponibles = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final cs = Theme.of(context).colorScheme;
    final Color cardBg = cs.surface;
    final Color textColor = cs.onSurface;
    final Color borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);

    return Scaffold(
      // Fondo y AppBar vienen del tema (misma paleta que Inicio).
      appBar: AppBar(
        title: const Text('Seleccionar Cita', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          Icon(Icons.calendar_month, color: context.brand),
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
                        firstDate: _hoy,
                        lastDate: _hoy.add(const Duration(days: 30)),
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
                          Icon(Icons.access_time_filled, color: context.brand),
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
                            selectedColor: context.brand,
                            backgroundColor: isDark ? AppColors.darkScaffold : const Color(0xFFF8FAFC),
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected ? context.onBrand : textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? context.brand : borderColor,
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
                      backgroundColor: context.brand,
                      disabledBackgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Continuar a Detalles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.onBrand,
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