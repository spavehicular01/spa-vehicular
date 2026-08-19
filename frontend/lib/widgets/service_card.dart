import 'package:flutter/material.dart';
import '../models/wash_service.dart';

class ServiceCard extends StatelessWidget {
  final WashService service;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagen o Icono por defecto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: service.imageUrl.isNotEmpty
                    ? Image.network(
                        service.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackIcon(),
                      )
                    : _buildFallbackIcon(),
              ),
              const SizedBox(width: 16),
              // Información del servicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Precio
              Text(
                '\$${service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.teal.shade50,
      child: const Icon(Icons.directions_car, size: 40, color: Colors.teal),
    );
  }
}