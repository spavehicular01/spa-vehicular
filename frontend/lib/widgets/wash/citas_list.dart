import 'package:flutter/material.dart';
import '../extras/ui_extras.dart';
import '../../theme/app_theme.dart';
import 'cita_card.dart';

/// Lista de citas con pull-to-refresh y estado vacío.
class CitasList extends StatelessWidget {
  final List<dynamic> citas;
  final bool esHistorial;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAgendar;

  const CitasList({
    super.key,
    required this.citas,
    required this.esHistorial,
    required this.onRefresh,
    this.onAgendar,
  });

  @override
  Widget build(BuildContext context) {
    if (citas.isEmpty) {
      return RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyState(
                icono: esHistorial ? Icons.history : Icons.event_available_outlined,
                titulo: esHistorial
                    ? 'Tu historial está vacío'
                    : 'No tienes citas activas',
                mensaje: esHistorial
                    ? 'Aquí verás tus lavadas finalizadas y canceladas.'
                    : 'Agenda una lavada y sigue su avance desde esta pantalla.',
                textoBoton: esHistorial ? null : 'Agendar cita',
                onPressed: esHistorial ? null : onAgendar,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: citas.length,
        itemBuilder: (context, index) => CitaCard(
          cita: citas[index],
          esHistorial: esHistorial,
        ),
      ),
    );
  }
}
