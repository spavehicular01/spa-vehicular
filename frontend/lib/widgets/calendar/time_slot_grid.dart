import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Grilla de cupos horarios del día seleccionado. Cada slot es un mapa con
/// las claves 'hora' (String), 'ocupado' (bool) y 'servicio' (String).
/// Al tocar un slot libre se llama a [onSlotTap] con ese slot.
class TimeSlotGrid extends StatelessWidget {
  final List<Map<String, dynamic>> horarios;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>> onSlotTap;

  const TimeSlotGrid({
    super.key,
    required this.horarios,
    required this.isLoading,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: horarios.length,
      itemBuilder: (context, index) {
        final slot = horarios[index];
        final bool estaOcupado = slot['ocupado'];

        return InkWell(
          onTap: estaOcupado ? null : () => onSlotTap(slot),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // Libre: cian AquaGlow al 10%. Ocupado: gris tenue.
              color: estaOcupado
                  ? Colors.grey.shade100
                  : const Color(0x1A00E5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estaOcupado ? Colors.grey.shade300 : AppColors.accent,
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
                    color: estaOcupado ? AppColors.muted : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estaOcupado
                      ? ((slot['servicio'] as String).isNotEmpty ? slot['servicio'] : 'Reservado')
                      : 'Agendar cita',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: estaOcupado ? AppColors.muted : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}