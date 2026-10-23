import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
class FormLabel extends StatelessWidget {
  final String texto;

  const FormLabel(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto, style: AppTextStyles.bodyStrong),
    );
  }
}