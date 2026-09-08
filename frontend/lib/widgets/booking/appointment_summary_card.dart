import 'package:flutter/material.dart';

/// Tarjeta informativa que muestra la fecha y el cupo horario seleccionados
/// para la cita.
class AppointmentSummaryCard extends StatelessWidget {
  final DateTime selectedDate;
  final String selectedTime;

  const AppointmentSummaryCard({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Hora del cupo: $selectedTime',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 30, 255),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}