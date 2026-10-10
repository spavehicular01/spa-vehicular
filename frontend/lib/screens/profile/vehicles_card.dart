import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Tarjeta "Mis Vehículos" con el conteo; al tocarla abre la lista.
class VehiclesCard extends StatelessWidget {
  final bool cargando;
  final int cantidad;
  final VoidCallback onTap;

  const VehiclesCard({
    super.key,
    required this.cargando,
    required this.cantidad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0x1A00E5FF),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: AppColors.secondary),
        title: const Text('Mis Vehículos'),
        subtitle: Text(
          cargando ? 'Cargando...' : '$cantidad vehículo(s) registrado(s)',
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.secondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
