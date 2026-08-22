import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

class AuthRequiredDialog extends StatelessWidget {
  const AuthRequiredDialog({super.key});

  /// Función estática auxiliar para mostrar el diálogo de forma fácil desde cualquier pantalla
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => const AuthRequiredDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.teal),
          SizedBox(width: 8),
          Text('Atención', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Para agendar un servicio en SPA Vehicular necesitas iniciar sesión o registrarte.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text('Registrarse'),
        ),
        ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
  ),
  onPressed: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onLoginExitoso: (_) {
            // El (_) ignora el parámetro enviado por LoginScreen
            Navigator.pop(context);
          },
        ),
      ),
    );
  },
          child: const Text('Iniciar Sesión'),
        ),
      ],
    );
  }
}