import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../extras/ui_extras.dart';
import 'home_data.dart';

/// Tarjeta "Horario y ubicación" con el botón "Cómo llegar".
class UbicacionCard extends StatelessWidget {
  const UbicacionCard({super.key});

  Future<void> _abrirMapa(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    void aviso() => messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el mapa.')),
        );

    try {
      final uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': kUbicacionMapa,
      });
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) aviso();
    } catch (_) {
      aviso();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FilaInfo(
              icono: Icons.schedule,
              lineas: [kHorarioSemana, kHorarioDomingo],
            ),
            const SizedBox(height: 14),
            const _FilaInfo(
              icono: Icons.place_outlined,
              lineas: [kDireccion],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _abrirMapa(context),
              icon: const Icon(Icons.directions, size: 20),
              label: const Text('Cómo llegar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final List<String> lineas;

  const _FilaInfo({required this.icono, required this.lineas});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: colorAcento(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in lineas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l,
                    style: AppTextStyles.body.copyWith(color: textoSuave(context)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}