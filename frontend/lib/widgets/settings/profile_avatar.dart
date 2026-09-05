import 'dart:io';
import 'package:flutter/material.dart';

/// Muestra el avatar del usuario (imagen local seleccionada, imagen de red,
/// o un ícono por defecto) con un botón flotante para cambiar la foto.
class ProfileAvatar extends StatelessWidget {
  final File? imagenSeleccionada;
  final String? avatarUrl;
  final VoidCallback onTapCambiarFoto;

  const ProfileAvatar({
    super.key,
    required this.imagenSeleccionada,
    required this.avatarUrl,
    required this.onTapCambiarFoto,
  });

  @override
  Widget build(BuildContext context) {
    final bool tieneAvatarUrl = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color.fromARGB(255, 0, 30, 255),
            backgroundImage: imagenSeleccionada != null
                ? FileImage(imagenSeleccionada!)
                : (tieneAvatarUrl ? NetworkImage(avatarUrl!) as ImageProvider : null),
            child: (imagenSeleccionada == null && !tieneAvatarUrl)
                ? const Icon(Icons.person, size: 55, color: Colors.white)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTapCambiarFoto,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}