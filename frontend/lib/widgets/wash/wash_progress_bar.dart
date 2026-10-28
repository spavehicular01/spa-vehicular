import 'package:flutter/material.dart';
import '../extras/ui_extras.dart';
import '../../theme/app_theme.dart';

/// Barra de progreso con los mismos pasos que maneja el administrador:
/// Pendiente → En Proceso → Completado.
class WashProgressBar extends StatelessWidget {
  final String estado;

  const WashProgressBar({super.key, required this.estado});

  static const _pasos = ['Pendiente', 'En Proceso', 'Completado'];

  int get _pasoActual {
    switch (estado.toLowerCase()) {
      case 'en_proceso':
        return 1;
      case 'finalizada':
        return 2;
      default: // pendiente, confirmada, reprogramada
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (estado.toLowerCase() == 'cancelada') return const SizedBox.shrink();

    final actual = _pasoActual;
    final activo = colorAcento(context);
    final inactivo = esOscuro(context)
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.grey.shade300;

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < _pasos.length; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: i < _pasos.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= actual ? activo : inactivo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < _pasos.length; i++)
              Expanded(
                child: Text(
                  _pasos[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == actual ? FontWeight.bold : FontWeight.normal,
                    color: i <= actual ? textoFuerte(context) : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
