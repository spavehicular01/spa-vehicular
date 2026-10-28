import 'package:flutter/material.dart';
import '../extras/ui_extras.dart';
import '../../theme/app_theme.dart';
import '../../utils/cita_helpers.dart';
import 'en_proceso_banner.dart';
import 'wash_progress_bar.dart';

/// Tarjeta de una cita en "Mis Lavadas".
class CitaCard extends StatelessWidget {
  final Map<String, dynamic> cita;
  final bool esHistorial;

  const CitaCard({super.key, required this.cita, required this.esHistorial});

  @override
  Widget build(BuildContext context) {
    final String estado = (cita['estado'] ?? 'pendiente').toString();
    final bool enProceso = estado.toLowerCase() == 'en_proceso';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: enProceso
            ? BorderSide(color: colorAcento(context), width: 1.5)
            : BorderSide(
                color: esOscuro(context)
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    obtenerNombreServicio(cita),
                    style: AppTextStyles.bodyStrong
                        .copyWith(color: textoFuerte(context)),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: obtenerEtiquetaEstado(estado),
                  color: obtenerColorEstado(estado),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              obtenerDescripcionServicio(cita),
              style: AppTextStyles.body.copyWith(color: textoSuave(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              '📅 Fecha/Hora: ${cita['fechaHoraCita'] ?? 'N/A'}',
              style: AppTextStyles.labelMuted
                  .copyWith(letterSpacing: 0, fontSize: 12),
            ),
            if (!esHistorial) ...[
              const SizedBox(height: 14),
              WashProgressBar(estado: estado),
            ],
            if (enProceso) ...[
              const SizedBox(height: 12),
              const EnProcesoBanner(),
            ],
          ],
        ),
      ),
    );
  }
}
