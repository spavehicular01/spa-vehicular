import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Tarjeta con preferencias globales de la app que aplican tanto para
/// usuarios autenticados como invitados: modo oscuro y tamaño de letra.
class GlobalSettingsCard extends StatelessWidget {
  final bool esModoOscuro;
  final double fontScale;
  final ValueChanged<bool> onCambiarModoOscuro;
  final ValueChanged<double> onCambiarTamanioLetra;

  const GlobalSettingsCard({
    super.key,
    required this.esModoOscuro,
    required this.fontScale,
    required this.onCambiarModoOscuro,
    required this.onCambiarTamanioLetra,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personalización Global', style: AppTextStyles.bodyStrong),
            SwitchListTile(
              secondary: Icon(
                esModoOscuro ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.secondary,
              ),
              title: const Text('Modo Oscuro'),
              value: esModoOscuro,
              activeColor: AppColors.accent,
              onChanged: onCambiarModoOscuro,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_size, color: AppColors.secondary),
                    SizedBox(width: 12),
                    Text('Tamaño de Letra Global'),
                  ],
                ),
                Text(
                  '${(fontScale * 100).round()}%',
                  style: AppTextStyles.bodyStrong,
                ),
              ],
            ),
            Slider(
              value: fontScale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              activeColor: AppColors.accent,
              onChanged: onCambiarTamanioLetra,
            ),
          ],
        ),
      ),
    );
  }
}
