import 'package:flutter/material.dart';
import '../services/wash_service.dart';

class HistoryWashesScreen extends StatelessWidget {
  const HistoryWashesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Lavadas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: WashApiService.getHistorialCitas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes lavadas en el historial.'));
          }

          final citas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: citas.length,
            itemBuilder: (context, index) {
              final cita = citas[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.teal, size: 32),
                  title: Text(cita['servicio'] ?? 'Servicio de Lavado', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fecha: ${cita['fecha'] ?? ''} - Hora: ${cita['hora'] ?? ''}\nVehículo: ${cita['vehiculo'] ?? 'N/A'}'),
                  trailing: Text(
                    '\$${cita['precio'] ?? '0'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 15),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
