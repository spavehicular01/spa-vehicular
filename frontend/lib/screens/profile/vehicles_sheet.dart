import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'vehicle_tile.dart';

/// Contenido del bottom sheet "Mis Vehículos".
class VehiclesSheet extends StatelessWidget {
  final bool cargando;
  final List<Map<String, String>> vehiculos;
  final VoidCallback onCerrar;
  final VoidCallback onAgregar;
  final void Function(Map<String, String> car) onEditar;
  final void Function(Map<String, String> car) onEliminar;

  const VehiclesSheet({
    super.key,
    required this.cargando,
    required this.vehiculos,
    required this.onCerrar,
    required this.onAgregar,
    required this.onEditar,
    required this.onEliminar,
  });

  Widget _lista() {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }
    if (vehiculos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No tienes vehículos registrados aún.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
      );
    }
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: vehiculos.length,
        itemBuilder: (context, index) {
          final car = vehiculos[index];
          return VehicleTile(
            car: car,
            onEditar: () => onEditar(car),
            onEliminar: () => onEliminar(car),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🚘 Mis Vehículos', style: AppTextStyles.h2),
              IconButton(icon: const Icon(Icons.close), onPressed: onCerrar),
            ],
          ),
          const Divider(),
          _lista(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Nuevo Vehículo'),
          ),
        ],
      ),
    );
  }
}
