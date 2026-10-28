import 'package:flutter/material.dart';
import '../../models/vehicle_types.dart';
import '../../theme/app_theme.dart';

/// Una fila de la lista de vehículos, con botones de editar y eliminar.
class VehicleTile extends StatelessWidget {
  final Map<String, String> car;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const VehicleTile({
    super.key,
    required this.car,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = car['tipoVehiculo'] ?? 'Vehículo';
    final marca = car['marca'] ?? '';
    final referencia = car['referencia'] ?? '';
    final placa = car['placa'] ?? '';
    final modelo = car['modelo'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          iconoTipoVehiculo(tipo),
          color: AppColors.secondary,
        ),
        title: Text('$marca $referencia ($placa)'),
        subtitle: Text('Tipo: ${etiquetaTipoVehiculo(tipo)} | Año: $modelo'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.secondary),
              onPressed: onEditar,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}
