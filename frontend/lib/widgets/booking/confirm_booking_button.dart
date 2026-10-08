import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Botón principal para confirmar el agendamiento. Muestra un spinner
/// mientras `isLoading` es verdadero y se deshabilita para evitar doble-tap.
/// Toma el estilo (cian con texto navy) del elevatedButtonTheme.
class ConfirmBookingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const ConfirmBookingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : const Text('Confirmar y Agendar'),
    );
  }
}
