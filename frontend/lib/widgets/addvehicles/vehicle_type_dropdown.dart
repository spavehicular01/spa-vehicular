import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'form_label.dart';

class VehicleTypeDropdown extends StatelessWidget {
  final String value;
  final List<String> opciones;
  final ValueChanged<String> onChanged;

  const VehicleTypeDropdown({
    super.key,
    required this.value,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormLabel('Tipo de Vehículo'),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: context.surfaceColor,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category, color: AppColors.secondary),
          ),
          items: opciones
              .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }
}