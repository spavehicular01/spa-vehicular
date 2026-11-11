import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dropdown para elegir el vehículo del usuario que se va a lavar.
/// Cada vehículo trae 'id' y 'nombre'. Si trae 'aplica' == 'false', el servicio
/// elegido no es para ese tipo de vehículo: sale en gris y no se puede elegir.
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
    final colorDeshabilitado = Theme.of(context).hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehículo a lavar:', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 8),
        // Sin dropdownColor fijo: el menú toma el color del tema (claro/oscuro).
        DropdownButtonFormField<String>(
          initialValue: vehiculoSeleccionadoId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.directions_car, color: AppColors.secondary),
          ),
          items: vehiculos.map((vehiculo) {
            final aplica = vehiculo['aplica'] != 'false';
            return DropdownMenuItem<String>(
              value: vehiculo['id'],
              enabled: aplica,
              child: Text(
                vehiculo['nombre']!,
                overflow: TextOverflow.ellipsis,
                style: aplica
                    ? null
                    : TextStyle(
                        color: colorDeshabilitado,
                        fontStyle: FontStyle.italic,
                      ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}