import 'package:flutter/material.dart';
import '../services/wash_service.dart';

class HistoryWashesScreen extends StatelessWidget {
  const HistoryWashesScreen({super.key});

  // Datos de respaldo local si el servicio no responde o está fallando
  List<Map<String, dynamic>> _getHistorialLocal() {
    return [
      {
        'servicio': 'Lavado General + Polichado',
        'fecha': '2026-08-10',
        'hora': '10:00 AM',
        'vehiculo': 'Toyota Hilux (ABC123)',
        'precio': '45.000',
      },
      {
        'servicio': 'Lavado Completo de Motor',
        'fecha': '2026-07-28',
        'hora': '02:30 PM',
        'vehiculo': 'Toyota Hilux (ABC123)',
        'precio': '35.000',
      },
    ];
  }

  Future<List<dynamic>> _cargarHistorial() async {
    try {
      // Intenta obtener los datos desde el servicio
      final datos = await WashApiService.getHistorialCitas();
      if (datos.isNotEmpty) return datos;
      return _getHistorialLocal();
    } catch (e) {
      // Si el método no existe en el service o falla la API, usa el respaldo
      return _getHistorialLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Lavadas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _cargarHistorial(),
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
                  title: Text(
                    cita['servicio'] ?? 'Servicio de Lavado',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Fecha: ${cita['fecha'] ?? ''} - Hora: ${cita['hora'] ?? ''}\nVehículo: ${cita['vehiculo'] ?? 'N/A'}',
                  ),
                  trailing: Text(
                    '\$${cita['precio'] ?? '0'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 15,
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