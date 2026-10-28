import 'package:flutter/material.dart';
import '../widgets/auth_required_dialog.dart';
import 'booking_screen.dart';
import '../services/wash_service.dart';
import '../theme/app_theme.dart';
import '../utils/horarios_spa.dart';

import '../widgets/calendar/date_picker_card.dart';
import '../widgets/calendar/slots_header.dart';
import '../widgets/calendar/time_slot_grid.dart';

class CalendarScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final String? token;
  final void Function(Map<String, dynamic> datos)? onLoginExitoso;

  /// Servicio que el cliente ya eligió en la pantalla de servicios (opcional).
  /// Se pasa a los detalles de la cita para que aparezca preseleccionado.
  final String? servicioInicialId;

  /// true cuando esta pantalla se abre desde la lista de servicios (como página
  /// propia): agrega su propio AppBar con el botón para volver. Dentro de la
  /// pestaña "Calendario" queda en false porque MainNavigationScreen ya tiene uno.
  final bool mostrarAppBar;

  const CalendarScreen({
    super.key,
    this.usuario,
    this.token,
    this.onLoginExitoso,
    this.servicioInicialId,
    this.mostrarAppBar = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  late List<Map<String, dynamic>> _horariosDisponibles =
      _horariosLibres(_selectedDate);

  /// Horas del día elegido (según el horario del spa), todas libres.
  /// Domingos y festivos solo hay horas en la mañana.
  List<Map<String, dynamic>> _horariosLibres(DateTime fecha) =>
      HorariosSpa.horasDelDia(fecha)
          .map((h) => {'hora': h, 'ocupado': false, 'servicio': '', 'disponibles': 5})
          .toList();

  /// Convierte '08:00 AM' / '02:00 PM' a hora de 24 h (8 / 14).
  int _horaA24(String hora) {
    final partes = hora.split(' ');
    final h = int.parse(partes[0].split(':')[0]);
    final esPM = partes[1].toUpperCase() == 'PM';
    if (esPM && h != 12) return h + 12;
    if (!esPM && h == 12) return 0;
    return h;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('--> USUARIO RECIBIDO EN CalendarScreen: ${widget.usuario}');
    _cargarCitasDelDia();
  }

  Future<void> _cargarCitasDelDia() async {
    final fechaConsultada = _selectedDate;
    setState(() => _isLoading = true);

    try {
      final fechaStr = fechaConsultada.toIso8601String().split('T')[0];
      final cupos = await WashApiService.getCuposDelDia(fechaStr);

      final listadoActualizado = HorariosSpa.horasDelDia(fechaConsultada).map((h) {
        final hora24 = _horaA24(h);
        final lleno = cupos.estaLleno(hora24);
        return {
          'hora': h,
          'ocupado': lleno,
          'servicio': lleno ? 'Sin cupos' : '',
          'disponibles': cupos.disponibles(hora24),
        };
      }).toList();

      // Si mientras tanto se eligió otro día, se descarta esta respuesta.
      if (mounted && fechaConsultada == _selectedDate) {
        setState(() {
          _horariosDisponibles = listadoActualizado;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar cupos del día: $e');
      // Si falla la consulta no se muestra el contador de cupos.
      if (mounted && fechaConsultada == _selectedDate) {
        setState(() {
          _horariosDisponibles = HorariosSpa.horasDelDia(fechaConsultada)
              .map((h) => {'hora': h, 'ocupado': false, 'servicio': '', 'disponibles': null})
              .toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _irAFormularioReserva(Map<String, dynamic> slot) async {
    // Protección extra: una hora llena no se puede agendar.
    if (slot['ocupado'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esa hora ya no tiene cupos disponibles. Elige otro horario.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String? token = widget.token;

    final bool hayToken = token != null && token.trim().isNotEmpty && token != 'null';
    final bool hayUsuario = widget.usuario != null &&
        (widget.usuario!['_id'] != null || widget.usuario!['id'] != null);

    if (!hayToken || !hayUsuario) {
      if (!mounted) return;

      AuthRequiredDialog.show(
        context,
        onLoginExitoso: (datos) {
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
          token: token,
          servicioInicialId: widget.servicioInicialId,
        ),
      ),
    );

    // Al volver (se haya agendado o no) se refrescan los cupos.
    if (mounted) _cargarCitasDelDia();

    // Si se abrió desde la lista de servicios y la cita quedó agendada,
    // se vuelve atrás para no dejar al cliente en una pantalla de calendario suelta.
    if (resultado == true && widget.mostrarAppBar && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          DatePickerCard(
            selectedDate: _selectedDate,
            onDateChanged: (newDate) {
              setState(() {
                _selectedDate = newDate;
                _horariosDisponibles = _horariosLibres(newDate);
              });
              _cargarCitasDelDia();
            },
          ),
          const SlotsHeader(),
          if (HorariosSpa.esDomingoOFestivo(_selectedDate))
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Domingos y festivos atendemos de 7:30 AM a 12:00 PM',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ),
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

    // En la pestaña "Calendario" no lleva Scaffold propio (lo provee MainNavigationScreen).
    if (!widget.mostrarAppBar) return contenido;

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar cita')),
      body: contenido,
    );
  }
}