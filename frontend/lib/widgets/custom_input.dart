import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomInput({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final Color inputBg = isDark ? AppColors.darkSurface : Colors.white;
    final Color textColor = isDark ? AppColors.darkText : AppColors.primary;
    final BorderSide side =
        isDark ? const BorderSide(color: AppColors.darkBorder) : BorderSide.none;
    final Color accent = isDark ? AppColors.accent : AppColors.secondary;

    OutlineInputBorder borde(BorderSide s) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: s,
        );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppColors.darkMuted : Colors.grey.shade700),
        prefixIcon: Icon(icon, color: accent),
        filled: true,
        fillColor: inputBg,
        border: borde(side),
        enabledBorder: borde(side),
        focusedBorder: borde(BorderSide(color: accent, width: 1.5)),
      ),
    );
  }
}