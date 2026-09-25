import 'package:flutter/material.dart';

/// Tarjeta que envuelve el CalendarDatePicker para elegir el día de la cita.
/// Nota: no hace falta fijar colores aquí — el CalendarDatePicker de
/// Material 3 hereda automáticamente el colorScheme (primary = navy,
/// secondary = cian) definido en AppTheme, y el Card ya viene redondeado
/// y con borde suave por el CardTheme global.
class DatePickerCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DatePickerCard({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        onDateChanged: onDateChanged,
      ),
    );
  }
}