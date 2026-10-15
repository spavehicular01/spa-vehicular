import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';
import 'service_prices_chips.dart';

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
                child: _buildImage(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre: más grande y en negrita para que sea lo primero que se vea
                    Text(
                      service.nombre,
                      style: AppTextStyles.bodyStrong.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Descripción: semi-negrita (w600). Para negrita completa usa FontWeight.w700.
                    Text(
                      service.descripcion,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    ServicePricesChips(service: service),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (service.imagenUrl.isNotEmpty) {
      return Image.network(
        service.imagenUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIcon(),
      );
    }
    return _buildIcon();
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