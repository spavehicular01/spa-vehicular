import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'form_label.dart';

/// Etiqueta + TextFormField con validación de "Campo requerido" por defecto.
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  static String? _requerido(String? val) =>
      val == null || val.isEmpty ? 'Campo requerido' : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.secondary),
          ),
          validator: validator ?? _requerido,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}