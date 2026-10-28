import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Pregunta si se quiere eliminar el vehículo. Devuelve true solo si confirma.
Future<bool?> confirmarEliminacionVehiculo(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Eliminar vehículo', style: AppTextStyles.h2),
      content: const Text(
        '¿Estás seguro de que deseas eliminar este vehículo?',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
