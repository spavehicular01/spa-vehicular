import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dropdown para elegir el vehículo del usuario que se va a lavar.
class VehicleSelector extends StatelessWidget {
  final List<Map<String, String>> vehiculos;
  final String? vehiculoSeleccionadoId;
  final ValueChanged<String?> onChanged;

  const VehicleSelector({
    super.key,
    required this.vehiculos,
    required this.vehiculoSeleccionadoId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehículo a lavar:', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: vehiculoSeleccionadoId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.directions_car, color: AppColors.secondary),
          ),
          items: vehiculos.map((vehiculo) {
            return DropdownMenuItem(
              value: vehiculo['id'],
              child: Text(vehiculo['nombre']!),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
