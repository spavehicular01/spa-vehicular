import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Foto, nombre, correo y botón "Editar perfil".
class ProfileHeader extends StatelessWidget {
  final String avatarUrl;
  final String nombreCompleto;
  final String correo;
  final VoidCallback onEditar;

  const ProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.nombreCompleto,
    required this.correo,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 12),
        Text(nombreCompleto, style: AppTextStyles.h2),
        Text(correo, style: AppTextStyles.body),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onEditar,
          icon: const Icon(Icons.edit, size: 18, color: AppColors.secondary),
          label: const Text(
            'Editar perfil',
            style: TextStyle(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}
