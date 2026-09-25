import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero, // el spacing entre cards ya lo maneja ServicesScreen
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildIcon(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.nombre,
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.descripcion,
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${service.precioBase.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.secondary, // azul agua, como los precios en AquaGlow
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0x1A00E5FF), // accent al 10%, mismo tono usado en HomeScreen
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.directions_car,
        size: 28,
        color: AppColors.secondary,
      ),
    );
  }
}