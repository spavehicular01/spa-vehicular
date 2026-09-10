import 'package:flutter/material.dart';

/// Tarjeta mostrada cuando el usuario no ha iniciado sesión, invitándolo
/// a autenticarse para acceder a la gestión de perfil.
class LoginPromptCard extends StatelessWidget {
  final VoidCallback onIniciarSesion;

  const LoginPromptCard({super.key, required this.onIniciarSesion});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 70, color: Color.fromARGB(255, 0, 30, 255)),
            const SizedBox(height: 12),
            const Text(
              '¡Bienvenido a Spa Vehicular!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para gestionar tus datos personales, consultar tus vehículos y reservar servicios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onIniciarSesion,
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión / Registrarse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}