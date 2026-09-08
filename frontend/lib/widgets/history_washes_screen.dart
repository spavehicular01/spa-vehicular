import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';

class HistoryWashesScreen extends StatelessWidget {
  const HistoryWashesScreen({super.key});

  List<Map<String, dynamic>> _getHistorialLocal() {
    return [
      {
        'servicio': 'Lavado General + Polichado',
        'fecha': '2026-08-10',
        'hora': '10:00 AM',
        'vehiculo': 'Toyota Hilux (ABC123)',
        'precio': '45.000',
        'estado': 'Completado',
      },
      {
        'servicio': 'Lavado Completo de Motor',
        'fecha': '2026-07-28',
        'hora': '02:30 PM',
        'vehiculo': 'Toyota Hilux (ABC123)',
        'precio': '35.000',
        'estado': 'Completado',
      },
    ];
  }

  Future<List<dynamic>> _cargarHistorial() async {
    try {
      const String usuarioId = 'ID_DEL_USUARIO';
      final res = await AppointmentService.obtenerCitasPorUsuario(usuarioId);
      if (res['success'] == true && res['citas'] != null) {
        final List<dynamic> citas = res['citas'];
        if (citas.isNotEmpty) return citas;
      }
      return _getHistorialLocal();
    } catch (_) {
      return _getHistorialLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Historial de Lavadas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppTheme.azulElectrico,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _cargarHistorial(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.azulElectrico));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes lavadas en el historial.'));
          }

          final citas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: citas.length,
            itemBuilder: (context, index) {
              final cita = citas[index];
              return AppointmentCard(
                servicio: cita['servicio'] ?? cita['nombreServicio'] ?? 'Servicio de Lavado',
                fecha: cita['fecha'] ?? cita['fechaHoraCita']?.toString().split('T').first ?? '',
                hora: cita['hora'] ?? '',
                vehiculo: cita['vehiculo'] ?? 'N/A',
                precio: cita['precio'] ?? cita['costo'] ?? '0',
                estado: 'Completado',
                isCompleted: true,
              );
            },
          );
        },
      ),
    );
  }
}