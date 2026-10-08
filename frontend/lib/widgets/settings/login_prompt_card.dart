import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Tarjeta mostrada cuando el usuario no ha iniciado sesión, invitándolo
/// a autenticarse para acceder a la gestión de perfil.
class LoginPromptCard extends StatelessWidget {
  final VoidCallback onIniciarSesion;

  const LoginPromptCard({super.key, required this.onIniciarSesion});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 70, color: AppColors.secondary),
            const SizedBox(height: 12),
            const Text('¡Bienvenido a Spa Vehicular!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para gestionar tus datos personales, consultar tus vehículos y reservar servicios.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            // Sin colores propios: hereda el ElevatedButtonTheme global (cian/navy).
            ElevatedButton.icon(
              onPressed: onIniciarSesion,
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión / Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
