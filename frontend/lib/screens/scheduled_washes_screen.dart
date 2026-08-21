import 'package:flutter/material.dart';
import '../services/wash_service.dart';

class ScheduledWashesScreen extends StatelessWidget {
  const ScheduledWashesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lavadas Programadas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: WashApiService.getCitasProgramadas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes lavadas programadas.'));
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
                  leading: const Icon(Icons.schedule, color: Colors.orange, size: 32),
                  title: Text(cita['servicio'] ?? 'Servicio de Lavado', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Fecha: ${cita['fecha'] ?? ''} - Hora: ${cita['hora'] ?? ''}\nVehículo: ${cita['vehiculo'] ?? 'N/A'}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cita['estado'] ?? 'Pendiente',
                      style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
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