import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Encabezado de la sección de horarios: título "Cupos del día" y la
/// leyenda de colores que indica disponible / ocupado.
class SlotsHeader extends StatelessWidget {
  const SlotsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Cupos del día', style: AppTextStyles.h2),
          Row(
            children: [
              const Icon(Icons.circle, color: AppColors.accent, size: 12),
              const SizedBox(width: 4),
              Text('Disponible', style: AppTextStyles.labelMuted.copyWith(letterSpacing: 0)),
              const SizedBox(width: 12),
              Icon(Icons.circle, color: AppColors.muted, size: 12),
              const SizedBox(width: 4),
              Text('Ocupado', style: AppTextStyles.labelMuted.copyWith(letterSpacing: 0)),
            ],
          ),
        ],
      ),
    );
  }
}