import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../extras/ui_extras.dart';

/// Carrusel horizontal de opiniones de clientes.
/// Cada opinión: {'nombre': String, 'estrellas': int, 'texto': String}.
class OpinionesCarrusel extends StatelessWidget {
  final List<Map<String, dynamic>> opiniones;

  const OpinionesCarrusel({super.key, required this.opiniones});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opiniones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _OpinionCard(opinion: opiniones[i]),
      ),
    );
  }
}

class _OpinionCard extends StatelessWidget {
  final Map<String, dynamic> opinion;

  const _OpinionCard({required this.opinion});

  @override
  Widget build(BuildContext context) {
    final estrellas = opinion['estrellas'] as int;

    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (int s = 0; s < 5; s++)
                    Icon(
                      s < estrellas
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  opinion['texto'] as String,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: textoSuave(context),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                opinion['nombre'] as String,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: textoFuerte(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
