import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dropdown para elegir el método de pago del servicio.
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
        const Text('Método de Pago:', style: AppTextStyles.bodyStrong),
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