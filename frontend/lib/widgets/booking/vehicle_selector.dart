import 'package:flutter/material.dart';

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
        const Text('Vehículo a lavar:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: vehiculoSeleccionadoId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_car),
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