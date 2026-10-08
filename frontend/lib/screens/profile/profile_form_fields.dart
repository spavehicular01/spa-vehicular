import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Campos del formulario de perfil: nombres, apellidos y celular.
class ProfileFormFields extends StatelessWidget {
  final TextEditingController nombresCtrl;
  final TextEditingController apellidosCtrl;
  final TextEditingController celularCtrl;
  final bool enabled;

  const ProfileFormFields({
    super.key,
    required this.nombresCtrl,
    required this.apellidosCtrl,
    required this.celularCtrl,
    required this.enabled,
  });

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: AppColors.secondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String? _validarNombre(String? v, String mensaje) {
    return (v == null || v.trim().length < 2) ? mensaje : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nombresCtrl,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: _decoracion('Nombres', Icons.person_outline),
          validator: (v) => _validarNombre(v, 'Ingresa tus nombres'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: apellidosCtrl,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: _decoracion('Apellidos', Icons.person_outline),
          validator: (v) => _validarNombre(v, 'Ingresa tus apellidos'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: celularCtrl,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _decoracion('Celular', Icons.phone_android),
          validator: (v) => (v == null || v.length != 10)
              ? 'El celular debe tener 10 dígitos'
              : null,
        ),
      ],
    );
  }
}
