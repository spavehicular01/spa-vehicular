import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dropdown para elegir cómo pagará el cliente AL RECOGER su vehículo.
/// No se cobra nada en la app: el pago real lo registra el administrador en el spa.
class PaymentMethodSelector extends StatelessWidget {
  final String metodoPago;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.metodoPago,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Cómo pagarás al recoger tu vehículo?', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 4),
        Text(
          'El pago se realiza en el spa al recoger tu vehículo. No se cobra nada en la app.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: metodoPago,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.payment, color: AppColors.secondary),
          ),
          items: opciones.map((metodo) {
            return DropdownMenuItem(value: metodo, child: Text(metodo));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}