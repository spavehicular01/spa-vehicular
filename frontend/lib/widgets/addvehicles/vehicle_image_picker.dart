import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
/// Caja de foto: muestra la imagen nueva, la existente (red) o un placeholder.
class VehicleImagePicker extends StatelessWidget {
  final XFile? imagenSeleccionada;
  final String? imagenUrlExistente;
  final VoidCallback onTap;

  const VehicleImagePicker({
    super.key,
    required this.imagenSeleccionada,
    required this.imagenUrlExistente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: _contenido(),
      ),
    );
  }

  Widget _contenido() {
    if (imagenSeleccionada != null) {
      return _imagenRedondeada(
        Image.file(File(imagenSeleccionada!.path), fit: BoxFit.cover),
      );
    }
    if (imagenUrlExistente != null && imagenUrlExistente!.isNotEmpty) {
      return _imagenRedondeada(
        Image.network(imagenUrlExistente!, fit: BoxFit.cover),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40, color: AppColors.secondary),
        SizedBox(height: 8),
        Text('Toca para agregar foto del vehículo', style: AppTextStyles.body),
      ],
    );
  }

  Widget _imagenRedondeada(Widget imagen) =>
      ClipRRect(borderRadius: BorderRadius.circular(16), child: imagen);
}