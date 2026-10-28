import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
    // En oscuro el azul agua casi no se ve: se usa el cian.
    final Color acento = context.isDark ? AppColors.accent : AppColors.secondary;

    return Card(
      color: AppColors.accent.withValues(alpha: 0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.event_available, color: acento, size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: AppTextStyles.h2.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hora del cupo: $selectedTime',
                  style: TextStyle(
                    color: acento,
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