import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../extras/ui_extras.dart';

/// Tarjeta "Tu próxima lavada". Muestra skeleton mientras carga, un estado
/// vacío si no hay sesión o citas, o los datos de la cita más cercana.
class ProximaCitaCard extends StatelessWidget {
  final bool cargando;
  final Map<String, dynamic>? cita;
  final bool logueado;

  /// Cambia de pestaña: 1 Calendario, 2 Lavadas, 3 Perfil.
  final void Function(int indice)? onIrATab;

  const ProximaCitaCard({
    super.key,
    required this.cargando,
    required this.cita,
    required this.logueado,
    this.onIrATab,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) return const _ProximaCitaSkeleton();

    final c = cita;
    if (c == null) return _buildVacio();

    final estado = (c['estado'] ?? 'pendiente').toString().toLowerCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.14),
                  child: Icon(Icons.local_car_wash, color: colorAcento(context)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreServicio(c),
                        style: AppTextStyles.bodyStrong
                            .copyWith(color: textoFuerte(context)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatearFecha(c['fechaHoraCita']),
                        style: AppTextStyles.body
                            .copyWith(color: textoSuave(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: _etiquetaEstado(estado),
                  color: _colorEstado(estado),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => onIrATab?.call(2),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Ver mis lavadas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: EmptyState(
          icono: Icons.event_available_outlined,
          titulo: logueado ? 'Aún no tienes citas' : 'Inicia sesión para agendar',
          mensaje: logueado
              ? 'Agenda tu primera lavada y sigue su estado desde aquí.'
              : 'Con tu cuenta puedes agendar y ver el estado de tus lavadas.',
          textoBoton: logueado ? 'Agendar ahora' : 'Iniciar sesión',
          onPressed: () => onIrATab?.call(logueado ? 1 : 3),
        ),
      ),
    );
  }
}

class _ProximaCitaSkeleton extends StatelessWidget {
  const _ProximaCitaSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 48, height: 48, radius: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 15),
                      SizedBox(height: 8),
                      SkeletonBox(width: 150, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SkeletonBox(height: 42, radius: 12),
          ],
        ),
      ),
    );
  }
}

// ───────────── Helpers de datos de la cita ─────────────

String _nombreServicio(Map<String, dynamic> cita) {
  final directo = cita['servicioNombre']?.toString() ?? '';
  if (directo.isNotEmpty) return directo;
  for (final clave in ['servicio', 'servicioId']) {
    final s = cita[clave];
    if (s is Map) {
      return (s['nombreServicio'] ?? s['nombre'] ?? 'Servicio de Lavado')
          .toString();
    }
  }
  return 'Servicio de Lavado';
}

String _formatearFecha(dynamic raw) {
  final dt = DateTime.tryParse('$raw')?.toLocal();
  if (dt == null) return raw?.toString() ?? 'Fecha por confirmar';
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
  ];
  const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final jornada = dt.hour < 12 ? 'a. m.' : 'p. m.';
  return '${dias[dt.weekday - 1]} ${dt.day} de ${meses[dt.month - 1]}, '
      '$h12:$min $jornada';
}

Color _colorEstado(String estado) {
  switch (estado) {
    case 'pendiente':
      return Colors.orange;
    case 'confirmada':
      return Colors.indigo;
    case 'en_proceso':
      return AppColors.secondary;
    case 'reprogramada':
      return Colors.purple;
    default:
      return AppColors.muted;
  }
}

String _etiquetaEstado(String estado) {
  switch (estado) {
    case 'pendiente':
      return 'Pendiente';
    case 'confirmada':
      return 'Confirmada';
    case 'en_proceso':
      return 'En proceso';
    case 'reprogramada':
      return 'Reprogramada';
    default:
      return estado;
  }
}
