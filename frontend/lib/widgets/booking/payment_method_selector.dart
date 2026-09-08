import 'package:flutter/material.dart';

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
        const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: metodoPago,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
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