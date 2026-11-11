import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dropdown para elegir el tipo de servicio de lavado.
/// Cada servicio trae 'id', 'nombre' y 'minutos' (duración estimada).
/// Si trae 'aplica' == false, el servicio no tiene precio para el vehículo
/// elegido: se ve en gris, pero sigue siendo seleccionable para que el cliente
/// pueda escoger primero el servicio y luego cambiar de vehículo.
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
    final colorNoAplica = Theme.of(context).hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de lavado:', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 8),
        // Sin dropdownColor fijo: el menú toma el color del tema (claro/oscuro).
        DropdownButtonFormField<String>(
          initialValue: servicioSeleccionadoId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.local_car_wash, color: AppColors.secondary),
          ),
          items: servicios.map((serv) {
            final aplica = serv['aplica'] != false;
            return DropdownMenuItem<String>(
              value: serv['id'] as String,
              child: Text(
                serv['nombre'] as String,
                overflow: TextOverflow.ellipsis,
                style: aplica
                    ? null
                    : TextStyle(
                        color: colorNoAplica,
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