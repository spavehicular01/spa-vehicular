import 'package:flutter/material.dart';

/// Botón principal para confirmar el agendamiento. Muestra un spinner
/// mientras `isLoading` es verdadero y se deshabilita para evitar doble-tap.
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
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 0, 30, 255),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              'Confirmar y Agendar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}