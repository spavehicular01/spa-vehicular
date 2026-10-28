import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Selector de modalidad del servicio (en el spa o a domicilio).
/// Cuando la modalidad es 'A domicilio', muestra un campo de dirección
/// obligatorio validado a través del Form padre.
class ModalitySelector extends StatelessWidget {
  final String modalidad;
  final ValueChanged<String?> onChanged;
  final TextEditingController direccionController;

  const ModalitySelector({
    super.key,
    required this.modalidad,
    required this.onChanged,
    required this.direccionController,
  });

  static const String valorSpa = 'Llevo el vehículo';
  static const String valorDomicilio = 'A domicilio';

  @override
  Widget build(BuildContext context) {
    final bool esDomicilio = modalidad == valorDomicilio;
    final Color acento = context.isDark ? AppColors.accent : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Dónde realizamos el servicio?:', style: AppTextStyles.bodyStrong),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Llevo el vehículo al spa', style: AppTextStyles.body),
          value: valorSpa,
          groupValue: modalidad,
          activeColor: acento,
          onChanged: onChanged,
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          title: const Text('A domicilio', style: AppTextStyles.body),
          value: valorDomicilio,
          groupValue: modalidad,
          activeColor: acento,
          onChanged: onChanged,
        ),
        if (esDomicilio) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: direccionController,
            decoration: InputDecoration(
              labelText: 'Dirección de residencia / entrega',
              prefixIcon: Icon(Icons.home, color: acento),
            ),
            validator: (val) {
              if (esDomicilio && (val == null || val.trim().isEmpty)) {
                return 'Ingresa tu dirección para el domicilio';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}