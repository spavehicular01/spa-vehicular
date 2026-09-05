import 'package:flutter/material.dart';

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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalización Global',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              secondary: Icon(
                esModoOscuro ? Icons.dark_mode : Icons.light_mode,
                color: const Color.fromARGB(255, 0, 30, 255),
              ),
              title: const Text('Modo Oscuro'),
              value: esModoOscuro,
              onChanged: onCambiarModoOscuro,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_size, color: Color.fromARGB(255, 0, 30, 255)),
                    SizedBox(width: 12),
                    Text('Tamaño de Letra Global'),
                  ],
                ),
                Text(
                  '${(fontScale * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: fontScale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              activeColor: const Color.fromARGB(255, 0, 30, 255),
              onChanged: onCambiarTamanioLetra,
            ),
          ],
        ),
      ),
    );
  }
}