import 'package:flutter/material.dart';
import '../extras/ui_extras.dart';


/// Aviso que aparece cuando el vehículo está siendo lavado.
class EnProcesoBanner extends StatelessWidget {
  const EnProcesoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1A00E5FF), // accent al 10%
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_car_wash, color: colorAcento(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '¡Tu vehículo se encuentra actualmente en proceso de lavado!',
              style: TextStyle(
                color: colorAcento(context),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}