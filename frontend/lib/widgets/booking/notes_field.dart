import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Campo de texto para sugerencias o especificaciones adicionales
/// que el cliente quiera dejar sobre el servicio (máx. 500 caracteres).
class NotesField extends StatelessWidget {
  final TextEditingController controller;

  const NotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sugerencias o especificaciones:', style: AppTextStyles.bodyStrong),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ej. Cuidado especial con el retrovisor derecho, manchas en el tapizado trasero...',
            hintStyle: TextStyle(color: AppColors.muted),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
