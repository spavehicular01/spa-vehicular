import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Grilla de cupos horarios del día seleccionado. Cada slot es un mapa con
/// las claves 'hora' (String), 'ocupado' (bool), 'servicio' (String) y,
/// opcionalmente, 'disponibles' (int: cupos que quedan en esa hora).
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

  String _textoCupos(int disponibles) =>
      disponibles == 1 ? 'Queda 1 cupo' : 'Quedan $disponibles cupos';

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: horarios.length,
        itemBuilder: (context, index) {
          final slot = horarios[index];
          final bool estaOcupado = slot['ocupado'] == true;
          final int? disponibles = slot['disponibles'] as int?;

          // Pocos cupos: se resalta en naranja para avisar que se está llenando.
          final bool pocosCupos = disponibles != null && disponibles <= 2;

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slot['hora'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: estaOcupado ? AppColors.muted : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estaOcupado ? 'Ocupado' : 'Agendar cita',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: estaOcupado ? AppColors.muted : AppColors.secondary,
                    ),
                  ),
                  if (!estaOcupado && disponibles != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      _textoCupos(disponibles),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: pocosCupos ? FontWeight.bold : FontWeight.normal,
                        color: pocosCupos
                            ? Colors.orange.shade800
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}