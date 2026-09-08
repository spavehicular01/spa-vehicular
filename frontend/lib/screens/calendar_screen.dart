import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/auth_required_dialog.dart';
import 'booking_screen.dart';
import '../services/appointment_service.dart';

import '../widgets/calendar/date_picker_card.dart';
import '../widgets/calendar/slots_header.dart';
import '../widgets/calendar/time_slot_grid.dart';

class CalendarScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final String? token;
  // 👇 nuevo: callback real que actualiza el estado de sesión en
  // MainNavigationScreen, para propagarlo si el login ocurre desde aquí.
  final void Function(Map<String, dynamic> datos)? onLoginExitoso;

  const CalendarScreen({
    super.key,
    this.usuario,
    this.token,
    this.onLoginExitoso,
  });

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
    debugPrint('--> USUARIO RECIBIDO EN CalendarScreen: ${widget.usuario}');
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

    if (token == null || token.trim().isEmpty || token == 'null') {
      if (!mounted) return;
      AuthRequiredDialog.show(
        context,
        onLoginExitoso: (datos) {
          // Propaga hacia MainNavigationScreen para que _usuarioAutenticado
          // se actualice de verdad y toda la app se entere de la sesión.
          widget.onLoginExitoso?.call(datos);
        },
      );
      return;
    }

    if (!mounted) return;

    debugPrint('--> usuario que se enviará a BookingScreen: ${widget.usuario}');

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda tu Cita'),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          DatePickerCard(
            selectedDate: _selectedDate,
            onDateChanged: (newDate) {
              setState(() => _selectedDate = newDate);
              _cargarCitasDelDia();
            },
          ),
          const SlotsHeader(),
          Expanded(
            child: TimeSlotGrid(
              horarios: _horariosDisponibles,
              isLoading: _isLoading,
              onSlotTap: _irAFormularioReserva,
            ),
          ),
        ],
      ),
    );
  }
}