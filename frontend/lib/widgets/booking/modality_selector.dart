import 'package:flutter/material.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Dónde realizamos el servicio?:', style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: const Text('Llevo el vehículo al spa'),
          value: valorSpa,
          groupValue: modalidad,
          activeColor: const Color.fromARGB(255, 0, 26, 255),
          onChanged: onChanged,
        ),
        RadioListTile<String>(
          title: const Text('A domicilio'),
          value: valorDomicilio,
          groupValue: modalidad,
          activeColor: const Color.fromARGB(255, 0, 26, 255),
          onChanged: onChanged,
        ),
        if (esDomicilio) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: direccionController,
            decoration: const InputDecoration(
              labelText: 'Dirección de residencia / entrega',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
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