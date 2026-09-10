import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  List<dynamic> _citas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final citas = await ApiService.obtenerTodasLasCitas();
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar citas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cambiarEstadoCita(String citaId, String nuevoEstado, int index) async {
    final exito = await ApiService.actualizarEstadoCita(citaId, nuevoEstado);

    if (!mounted) return;

    if (exito) {
      setState(() {
        _citas[index]['estado'] = nuevoEstado;
      });

      String mensaje = 'Estado actualizado a "$nuevoEstado"';
      if (nuevoEstado == 'En Proceso') {
        mensaje = '🧼 Notificación enviada: ¡Lavado iniciado!';
      } else if (nuevoEstado == 'Completado') {
        mensaje = '✅ Notificación enviada: ¡Lavado finalizado!';
      } else if (nuevoEstado == 'Cancelado') {
        mensaje = '❌ La cita ha sido cancelada.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: const Color.fromARGB(255, 0, 42, 255),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado en el servidor'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _obtenerColorEstado(String? estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Proceso':
        return Colors.blue;
      case 'Completado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Auxiliar para extraer el nombre del usuario (maneja populate de MongoDB o strings simples)
  String _obtenerNombreUsuario(dynamic cita) {
    if (cita['usuarioId'] is Map) {
      return cita['usuarioId']['nombre'] ?? cita['usuarioId']['nombreCompleto'] ?? 'Cliente sin nombre';
    }
    return cita['nombreCliente'] ?? cita['usuario'] ?? 'Cliente sin nombre';
  }

  // Auxiliar para extraer los datos del vehículo
  String _obtenerDetalleVehiculo(dynamic cita) {
    if (cita['vehiculoId'] is Map) {
      final v = cita['vehiculoId'];
      return '${v['placa'] ?? ''} - ${v['marca'] ?? ''} ${v['modelo'] ?? ''}'.trim();
    }
    return cita['vehiculo'] ?? cita['vehiculoId'] ?? 'N/A';
  }

  // Auxiliar para extraer el servicio
  String _obtenerDetalleServicio(dynamic cita) {
    if (cita['servicioId'] is Map) {
      return cita['servicioId']['nombre'] ?? 'Servicio Estándar';
    }
    return cita['servicio'] ?? 'Servicio General';
  }

  // Formateador simple de fecha
  String _formatearFecha(String? fechaIso, String? hora) {
    if (fechaIso == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaIso);
      final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
      return hora != null ? '$fechaStr ($hora)' : fechaStr;
    } catch (_) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas (Admin)'),
        backgroundColor: const Color.fromARGB(255, 0, 42, 255),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarCitas,
              child: _citas.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No hay citas registradas.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _citas.length,
                      itemBuilder: (context, index) {
                        final cita = _citas[index];
                        final estadoActual = cita['estado'] ?? 'Pendiente';
                        final citaId = cita['_id'] ?? cita['id'];

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _obtenerNombreUsuario(cita),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _obtenerColorEstado(estadoActual).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _obtenerColorEstado(estadoActual)),
                                      ),
                                      child: Text(
                                        estadoActual,
                                        style: TextStyle(
                                          color: _obtenerColorEstado(estadoActual),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('🧼 Servicio: ${_obtenerDetalleServicio(cita)}'),
                                Text('🚗 Vehículo: ${_obtenerDetalleVehiculo(cita)}'),
                                Text('📅 Fecha: ${_formatearFecha(cita['fechaHoraCita'], cita['hora'])}'),
                                if (cita['modalidad'] != null)
                                  Text('📍 Modalidad: ${cita['modalidad'] == 'a_domicilio' ? 'A Domicilio' : 'En Spa'}'),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    PopupMenuButton<String>(
                                      onSelected: (nuevoEstado) {
                                        if (citaId != null) {
                                          _cambiarEstadoCita(citaId, nuevoEstado, index);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'En Proceso',
                                          child: Row(
                                            children: [
                                              Icon(Icons.play_arrow, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Iniciar Lavada (En Proceso)'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'Completado',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Finalizar Lavada (Completado)'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'Cancelado',
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Cancelar Cita'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 0, 38, 255),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Text(
                                              'Cambiar Estado',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down, color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}