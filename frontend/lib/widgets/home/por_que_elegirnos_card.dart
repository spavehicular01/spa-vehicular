import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../extras/ui_extras.dart';

/// Tarjeta con 3 razones para elegir el servicio.
class PorQueElegirnosCard extends StatelessWidget {
  const PorQueElegirnosCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Razon(icono: Icons.water_drop_outlined, texto: 'Uso responsable del agua'),
            _Razon(icono: Icons.workspace_premium_outlined, texto: 'Productos premium'),
            _Razon(icono: Icons.verified_user_outlined, texto: 'Personal capacitado'),
          ],
        ),
      ),
    );
  }
}

class _Razon extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Razon({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accent.withValues(alpha: 0.14),
            child: Icon(icono, color: colorAcento(context), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: AppTextStyles.body
                .copyWith(color: textoSuave(context), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}