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

  InputDecoration _decoracion(BuildContext context, String etiqueta, IconData icono) {
    // En oscuro el campo es un poco más oscuro que el sheet para que se distinga.
    final Color relleno =
        context.isDark ? AppColors.darkScaffold : AppColors.background;

    OutlineInputBorder borde(Color color, [double ancho = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: ancho),
      );
    }

    return InputDecoration(
      labelText: etiqueta,
      labelStyle: TextStyle(color: context.mutedColor),
      floatingLabelStyle: TextStyle(color: context.brandText),
      prefixIcon: Icon(icono, color: context.brandText),
      filled: true,
      fillColor: relleno,
      border: borde(context.borderColor),
      enabledBorder: borde(context.borderColor),
      disabledBorder: borde(context.borderColor),
      focusedBorder: borde(AppColors.accent, 1.5),
    );
  }

  String? _validarNombre(String? v, String mensaje) {
    return (v == null || v.trim().length < 2) ? mensaje : null;
  }

  @override
  Widget build(BuildContext context) {
    final estiloTexto = TextStyle(color: context.textColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nombresCtrl,
          enabled: enabled,
          style: estiloTexto,
          textCapitalization: TextCapitalization.words,
          decoration: _decoracion(context, 'Nombres', Icons.person_outline),
          validator: (v) => _validarNombre(v, 'Ingresa tus nombres'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: apellidosCtrl,
          enabled: enabled,
          style: estiloTexto,
          textCapitalization: TextCapitalization.words,
          decoration: _decoracion(context, 'Apellidos', Icons.person_outline),
          validator: (v) => _validarNombre(v, 'Ingresa tus apellidos'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: celularCtrl,
          enabled: enabled,
          style: estiloTexto,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _decoracion(context, 'Celular', Icons.phone_android),
          validator: (v) => (v == null || v.length != 10)
              ? 'El celular debe tener 10 dígitos'
              : null,
        ),
      ],
    );
  }
}