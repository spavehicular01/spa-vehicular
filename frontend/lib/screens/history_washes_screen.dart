import 'package:flutter/material.dart';
import '../services/wash_api_service.dart';
import '../theme/app_theme.dart';

class HistoryWashesScreen extends StatelessWidget {
  const HistoryWashesScreen({super.key});

  // Datos de respaldo SOLO para cuando falla la conexión con el backend
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
      final datos = await WashApiService.getHistorialCitas();
      return datos; // Aunque venga vacío [], es una respuesta válida del backend
    } catch (e) {
      // Solo usamos el respaldo local si la petición realmente falló
      return _getHistorialLocal();
    }
  }

  // --- Helpers de mapeo ---

  String _extraerServicio(Map cita) {
    final directo = cita['servicio'];
    if (directo is String) return directo;

    final servicioObj = cita['servicioId'];
    if (servicioObj is Map && servicioObj['nombreServicio'] != null) {
      return servicioObj['nombreServicio'].toString();
    }
    return 'Servicio de Lavado';
  }

  String _extraerVehiculo(Map cita) {
    final directo = cita['vehiculo'];
    if (directo is String) return directo;

    final vehiculoObj = cita['vehiculoId'];
    if (vehiculoObj is Map) {
      final marca = vehiculoObj['marca'];
      final modelo = vehiculoObj['modelo'];
      final placa = vehiculoObj['placa'];
      final partes = [
        if (marca != null) marca,
        if (modelo != null) modelo,
      ].join(' ');
      if (partes.isNotEmpty && placa != null) return '$partes ($placa)';
      if (partes.isNotEmpty) return partes;
      if (placa != null) return '$placa';
    }
    return 'N/A';
  }

  String _extraerPrecio(Map cita) {
    final directo = cita['precio'];
    if (directo != null) return directo.toString();

    final servicioObj = cita['servicioId'];
    final vehiculoObj = cita['vehiculoId'];

    if (servicioObj is Map) {
      final precios = servicioObj['precios'];
      if (precios is List && precios.isNotEmpty) {
        final tipoVehiculo = vehiculoObj is Map ? vehiculoObj['tipoVehiculo'] : null;

        if (tipoVehiculo != null) {
          final match = precios.firstWhere(
            (p) => p is Map && p['tipoVehiculo'] == tipoVehiculo,
            orElse: () => null,
          );
          if (match != null && match['precio'] != null) {
            return match['precio'].toString();
          }
        }

        final primerPrecio = precios.first;
        if (primerPrecio is Map && primerPrecio['precio'] != null) {
          return primerPrecio['precio'].toString();
        }
      }
    }
    return '0';
  }

  String _extraerFecha(Map cita) {
    final directa = cita['fecha'];
    if (directa is String) return directa;

    final fechaHora = cita['fechaHoraCita'];
    if (fechaHora != null) {
      final dt = DateTime.tryParse(fechaHora.toString());
      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }
    return '';
  }

  String _extraerHora(Map cita) {
    final directa = cita['hora'];
    if (directa is String) return directa;

    final fechaHora = cita['fechaHoraCita'];
    if (fechaHora != null) {
      final dt = DateTime.tryParse(fechaHora.toString());
      if (dt != null) {
        final hora = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hora:${dt.minute.toString().padLeft(2, '0')} $ampm';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Reportes e Historial'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _cargarHistorial(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.azulElectrico),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar el historial: ${snapshot.error}',
                style: TextStyle(color: textColor),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No tienes lavadas en el historial.',
                style: TextStyle(fontSize: 16, color: subtitleColor),
              ),
            );
          }

          final citas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: citas.length,
            itemBuilder: (context, index) {
              final cita = citas[index] as Map;
              return Card(
                color: cardBg,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.teal, size: 32),
                  title: Text(
                    _extraerServicio(cita),
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text(
                    'Fecha: ${_extraerFecha(cita)} - Hora: ${_extraerHora(cita)}\nVehículo: ${_extraerVehiculo(cita)}',
                    style: TextStyle(color: subtitleColor),
                  ),
                  trailing: Text(
                    '\$${_extraerPrecio(cita)}',
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