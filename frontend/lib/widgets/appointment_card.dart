import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppointmentCard extends StatelessWidget {
  final String servicio;
  final String fecha;
  final String hora;
  final String vehiculo;
  final String? precio;
  final String estado;
  final bool isCompleted;
  final VoidCallback? onCancel;

  const AppointmentCard({
    super.key,
    required this.servicio,
    required this.fecha,
    required this.hora,
    required this.vehiculo,
    this.precio,
    required this.estado,
    this.isCompleted = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    final Color statusColor = isCompleted ? Colors.green : Colors.orange;
    final IconData statusIcon = isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded;

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
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              title: Text(
                servicio,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha: $fecha ${hora.isNotEmpty ? "- $hora" : ""}',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vehículo: $vehiculo',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              trailing: precio != null
                  ? Text(
                      '\$$precio',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.azulElectrico,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            if (onCancel != null) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                  label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}