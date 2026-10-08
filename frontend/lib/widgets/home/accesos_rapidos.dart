import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../extras/ui_extras.dart';

/// Cuadrícula 2x2 con los accesos rápidos del Inicio.
class AccesosRapidos extends StatelessWidget {
  final VoidCallback onServicios;
  final VoidCallback onAgendar;
  final VoidCallback onVehiculos;
  final VoidCallback onLavadas;

  const AccesosRapidos({
    super.key,
    required this.onServicios,
    required this.onAgendar,
    required this.onVehiculos,
    required this.onLavadas,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _AccesoCard(
          icono: Icons.cleaning_services,
          color: const Color(0xFF0077B6),
          titulo: 'Servicios',
          detalle: 'Catálogo y precios',
          onTap: onServicios,
        ),
        _AccesoCard(
          icono: Icons.calendar_month,
          color: const Color(0xFF00A7C4),
          titulo: 'Agendar cita',
          detalle: 'Elige día y hora',
          onTap: onAgendar,
        ),
        _AccesoCard(
          icono: Icons.directions_car_filled,
          color: const Color(0xFF5C6BC0),
          titulo: 'Mis vehículos',
          detalle: 'Registra y edita',
          onTap: onVehiculos,
        ),
        _AccesoCard(
          icono: Icons.local_car_wash,
          color: const Color(0xFF26A69A),
          titulo: 'Mis lavadas',
          detalle: 'Estado e historial',
          onTap: onLavadas,
        ),
      ],
    );
  }
}

class _AccesoCard extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _AccesoCard({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icono, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppTextStyles.bodyStrong
                        .copyWith(color: textoFuerte(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(color: textoSuave(context), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
