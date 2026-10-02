import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Foto circular con icono de cámara y una leyenda; al tocarla se elige otra foto.
class AvatarPicker extends StatelessWidget {
  final ImageProvider? imagen;
  final VoidCallback? onTap;

  const AvatarPicker({super.key, required this.imagen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.primary,
                backgroundImage: imagen,
                child: imagen == null
                    ? const Icon(Icons.person, size: 55, color: Colors.white)
                    : null,
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text('Toca la foto para cambiarla', style: AppTextStyles.body),
      ],
    );
  }
}