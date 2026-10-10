import 'package:flutter/material.dart';

/// Fila de 5 estrellas (solo lectura).
class EstrellasFila extends StatelessWidget {
  final int calificacion;
  final double tamano;

  const EstrellasFila({super.key, required this.calificacion, this.tamano = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < calificacion ? Icons.star_rounded : Icons.star_outline_rounded,
          size: tamano,
          color: const Color(0xFFFFB400),
        ),
      ),
    );
  }
}

/// Tarjeta de una opinión dentro del carrusel.
class OpinionCard extends StatelessWidget {
  final Map<String, dynamic> opinion;

  const OpinionCard({super.key, required this.opinion});

  @override
  Widget build(BuildContext context) {
    final calificacion = (opinion['calificacion'] as num?)?.toInt() ?? 0;
    final comentario = (opinion['comentario'] ?? '').toString().trim();
    final nombre = (opinion['nombre'] ?? 'Cliente').toString();

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstrellasFila(calificacion: calificacion),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              comentario.isEmpty ? 'Sin comentario' : comentario,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: comentario.isEmpty ? Colors.black38 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}