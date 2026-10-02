import 'package:flutter/material.dart';

/// Botón "Guardar cambios" que muestra un spinner mientras se guarda.
class SaveButton extends StatelessWidget {
  final bool guardando;
  final VoidCallback onPressed;

  const SaveButton({super.key, required this.guardando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: guardando ? null : onPressed,
      icon: guardando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(guardando ? 'Guardando...' : 'Guardar cambios'),
    );
  }
}