import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/auth_required_dialog.dart';
import 'booking_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  // Horarios de la jornada
  final List<Map<String, dynamic>> _horariosDisponibles = [
    {'hora': '08:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '09:00 AM', 'ocupado': true, 'servicio': 'Lavado Básico'},
    {'hora': '10:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '11:00 AM', 'ocupado': false, 'servicio': ''},
    {'hora': '02:00 PM', 'ocupado': false, 'servicio': ''},
    {'hora': '03:00 PM', 'ocupado': true, 'servicio': 'Polichado y Encerado'},
    {'hora': '04:00 PM', 'ocupado': false, 'servicio': ''},
    {'hora': '05:00 PM', 'ocupado': false, 'servicio': ''},
  ];

  // Redirige a la pantalla de detalles de reserva al tocar un cupo disponible
  void _irAFormularioReserva(Map<String, dynamic> slot) async {
    // 1. Validar token de autenticación antes de navegar
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null || token.trim().isEmpty || token == 'null') {
      if (!mounted) return;
      AuthRequiredDialog.show(context);
      return; // Cancela el flujo si el usuario no ha iniciado sesión
    }

    if (!mounted) return;

    // 2. Si hay token, navegar a BookingScreen
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          selectedDate: _selectedDate,
          selectedTime: slot['hora'],
        ),
      ),
    );

    // Si el usuario confirmó la reserva en BookingScreen, marcamos el cupo como ocupado
    if (resultado != null && resultado is Map<String, dynamic>) {
      setState(() {
        slot['ocupado'] = true;
        slot['servicio'] = resultado['servicio'] ?? 'Reservado';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda tu Cita'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Calendario con localización
          Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              onDateChanged: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cupos del día',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Color.fromARGB(255, 0, 34, 255), size: 12),
                    SizedBox(width: 4),
                    Text('Disponible', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 12),
                    Icon(Icons.circle, color: Color.fromARGB(255, 158, 158, 158), size: 12),
                    SizedBox(width: 4),
                    Text('Ocupado', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Bloques de horarios protegidos con el widget Material
          Expanded(
            child: GridView.builder(
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

                return InkWell(
                  onTap: estaOcupado
                      ? null
                      : () => _irAFormularioReserva(slot),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: estaOcupado
                          ? Colors.grey.shade200
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: estaOcupado ? const Color.fromARGB(255, 158, 158, 158) : Colors.teal,
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
                            color: estaOcupado
                                ? const Color.fromARGB(255, 158, 158, 158)
                                : const Color.fromARGB(255, 0, 11, 105),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          estaOcupado
                              ? (slot['servicio'].isNotEmpty
                                  ? slot['servicio']
                                  : 'Reservado')
                              : 'Agendar cita',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: estaOcupado ? const Color.fromARGB(255, 158, 158, 158) : const Color.fromARGB(255, 0, 30, 255),
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
    );
  }
}