import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dropdown para elegir el tipo de servicio de lavado.
/// Cada servicio trae 'id', 'nombre' y 'minutos' (duración estimada).
class ServiceSelector extends StatelessWidget {
  final List<Map<String, dynamic>> servicios;
  final String? servicioSeleccionadoId;
  final ValueChanged<String?> onChanged;

  const ServiceSelector({
    super.key,
    required this.servicios,
    required this.servicioSeleccionadoId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de lavado:', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: servicioSeleccionadoId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.local_car_wash, color: AppColors.secondary),
          ),
          items: servicios.map((serv) {
            return DropdownMenuItem(
              value: serv['id'] as String,
              child: Text(serv['nombre'] as String),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
