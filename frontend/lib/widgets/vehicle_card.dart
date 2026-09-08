import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VehicleCard extends StatelessWidget {
  final String placa;
  final String marca;
  final String modelo;
  final String? imagenUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleCard({
    super.key,
    required this.placa,
    required this.marca,
    required this.modelo,
    this.imagenUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Card(
      elevation: 2,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Contenedor de la imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
                child: imagenUrl != null && imagenUrl!.isNotEmpty
                    ? Image.network(
                        imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: AppTheme.azulElectrico, size: 36),
                      )
                    : const Icon(Icons.directions_car, color: AppTheme.azulElectrico, size: 36),
              ),
            ),
            const SizedBox(width: 14),

            // Detalles del vehículo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placa,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$marca - $modelo',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Acciones (Editar y Eliminar)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.azulElectrico),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}