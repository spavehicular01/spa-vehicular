import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VehicleListTile extends StatelessWidget {
  final Map<String, dynamic> vehiculo;
  final VoidCallback onDelete;
  final bool isDark;

  const VehicleListTile({
    super.key,
    required this.vehiculo,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMoto = vehiculo['tipoVehiculo'] == 'moto';

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.azulElectrico.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isMoto ? Icons.two_wheeler : Icons.directions_car,
            color: AppTheme.azulElectrico,
            size: 28,
          ),
        ),
        title: Text(
          '${vehiculo['marca']} ${vehiculo['referencia'] ?? ''}'.trim(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Placa: ${vehiculo['placa']} • Modelo: ${vehiculo['modelo'] ?? 'N/A'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}