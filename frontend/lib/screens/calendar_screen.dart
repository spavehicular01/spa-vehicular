import 'package:flutter/material.dart';
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

      setState(() {
        _horariosDisponibles = listadoActualizado;
      });
    } catch (e) {
      // Manejo de error de red opcional
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _irAFormularioReserva(Map<String, dynamic> slot) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          selectedDate: _selectedDate,
          selectedTime: slot['hora'],
          usuario: widget.usuario,
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
    return Column(
      children: [
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
              _cargarCitasDelDia();
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
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
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

                    return InkWell(
                      onTap: estaOcupado ? null : () => _irAFormularioReserva(slot),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: estaOcupado ? Colors.grey.shade200 : Colors.teal.shade50,
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
                                  ? (slot['servicio'].isNotEmpty ? slot['servicio'] : 'Reservado')
                                  : 'Agendar cita',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: estaOcupado
                                    ? const Color.fromARGB(255, 158, 158, 158)
                                    : const Color.fromARGB(255, 0, 30, 255),
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
    );
  }
}