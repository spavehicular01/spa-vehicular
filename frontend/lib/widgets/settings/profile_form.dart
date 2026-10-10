import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Formulario editable con los datos personales del usuario autenticado.
/// No maneja su propio estado de guardado; recibe `isLoading` y `onGuardar`
/// desde el widget padre para mantener la lógica de red centralizada.
class ProfileForm extends StatelessWidget {
  final TextEditingController documentoController;
  final TextEditingController correoController;
  final TextEditingController nombresController;
  final TextEditingController apellidosController;
  final TextEditingController celularController;
  final bool isLoading;
  final VoidCallback onGuardar;

  const ProfileForm({
    super.key,
    required this.documentoController,
    required this.correoController,
    required this.nombresController,
    required this.apellidosController,
    required this.celularController,
    required this.isLoading,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: documentoController,
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Documento de Identidad (No editable)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: correoController,
          enabled: false,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico (No editable)',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nombresController,
          decoration: const InputDecoration(
            labelText: 'Nombres',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: apellidosController,
          decoration: const InputDecoration(
            labelText: 'Apellidos',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: celularController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Celular',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 24),
        // Sin colores propios: hereda el ElevatedButtonTheme global (cian/navy).
        ElevatedButton(
          onPressed: isLoading ? null : onGuardar,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                )
              : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
