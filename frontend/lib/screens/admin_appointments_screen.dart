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
    setState(() => _cargando = true);
    try {
      // Reemplaza por el ID correspondiente o la petición global de citas
      final citas = await ApiService.obtenerTodasLasCitas(); 
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar citas: $e')),
      );
    }
  }

  Future<void> _cambiarEstadoCita(String citaId, String nuevoEstado, int index) async {
    final exito = await ApiService.actualizarEstadoCita(citaId, nuevoEstado);

    if (exito) {
      setState(() {
        _citas[index]['estado'] = nuevoEstado;
      });

      String mensaje = 'Estado actualizado a "$nuevoEstado"';
      if (nuevoEstado == 'En Proceso') {
        mensaje = '🧼 Notificación y correo enviados: ¡Lavado iniciado!';
      } else if (nuevoEstado == 'Completado') {
        mensaje = '✅ Notificación y correo enviados: ¡Lavado finalizado y enviado al historial!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.teal,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas (Admin)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _citas.isEmpty
              ? const Center(child: Text('No hay citas registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _citas.length,
                  itemBuilder: (context, index) {
                    final cita = _citas[index];
                    final estadoActual = cita['estado'] ?? 'Pendiente';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cita['nombreCliente'] ?? 'Cliente sin nombre',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            Text('🚗 Vehículo ID: ${cita['vehiculoId'] ?? 'N/A'}'),
                            Text('📅 Fecha: ${cita['fechaHoraCita'] ?? 'Sin fecha'}'),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (nuevoEstado) =>
                                      _cambiarEstadoCita(cita['_id'], nuevoEstado, index),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'En Proceso',
                                      child: Row(
                                        children: [
                                          Icon(Icons.play_arrow, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Iniciar Lavada (En Proceso)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Completado',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Finalizar Lavada (Completado)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
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
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text(
                                          'Cambiar Estado',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }
}