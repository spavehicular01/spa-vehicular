import 'package:flutter/material.dart';

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
        const Text('Tipo de lavado:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: servicioSeleccionadoId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_car_wash),
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