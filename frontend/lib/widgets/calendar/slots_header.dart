import 'package:flutter/material.dart';

/// Encabezado de la sección de horarios: título "Cupos del día" y la
/// leyenda de colores que indica disponible / ocupado.
class SlotsHeader extends StatelessWidget {
  const SlotsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cupos del día',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(Icons.circle, color: Color.fromARGB(255, 0, 34, 255), size: 12),
              SizedBox(width: 4),
              Text('Disponible', style: TextStyle(fontSize: 12)),
              SizedBox(width: 12),
              Icon(Icons.circle, color: Color.fromARGB(255, 158, 158, 158), size: 12),
              SizedBox(width: 4),
              Text('Ocupado', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}