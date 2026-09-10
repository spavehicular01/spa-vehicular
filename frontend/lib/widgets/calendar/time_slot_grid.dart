import 'package:flutter/material.dart';

/// Grilla de cupos horarios del día seleccionado. Cada slot es un mapa con
/// las claves 'hora' (String), 'ocupado' (bool) y 'servicio' (String).
/// Al tocar un slot libre se llama a [onSlotTap] con ese slot.
class TimeSlotGrid extends StatelessWidget {
  final List<Map<String, dynamic>> horarios;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>> onSlotTap;

  const TimeSlotGrid({
    super.key,
    required this.horarios,
    required this.isLoading,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color.fromARGB(255, 0, 26, 255)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: horarios.length,
      itemBuilder: (context, index) {
        final slot = horarios[index];
        final bool estaOcupado = slot['ocupado'];

        return InkWell(
          onTap: estaOcupado ? null : () => onSlotTap(slot),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: estaOcupado ? Colors.grey.shade200 : Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estaOcupado
                    ? const Color.fromARGB(255, 158, 158, 158)
                    : const Color.fromARGB(255, 0, 26, 255),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot['hora'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: estaOcupado
                        ? const Color.fromARGB(255, 158, 158, 158)
                        : const Color.fromARGB(255, 0, 11, 105),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estaOcupado
                      ? ((slot['servicio'] as String).isNotEmpty ? slot['servicio'] : 'Reservado')
                      : 'Agendar cita',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: estaOcupado
                        ? const Color.fromARGB(255, 158, 158, 158)
                        : const Color.fromARGB(255, 0, 30, 255),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}