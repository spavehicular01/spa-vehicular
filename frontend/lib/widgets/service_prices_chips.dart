import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/vehicle_types.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// Muestra solo los precios que tiene el servicio, uno por tipo de vehículo.
class ServicePricesChips extends StatelessWidget {
  final ServiceModel service;

  const ServicePricesChips({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final precios = service.preciosOrdenados;
    if (precios.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in precios)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x1A00E5FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${etiquetaTipoVehiculo(p.tipoVehiculo)}: ${formatearPesos(p.precio)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
      ],
    );
  }
}