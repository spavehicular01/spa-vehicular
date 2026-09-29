import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
      if (nuevoEstado == 'en_proceso') {
        mensaje = '🧼 Notificación enviada: ¡Lavado iniciado!';
      } else if (nuevoEstado == 'finalizada') {
        mensaje = '✅ Notificación enviada: ¡Lavado finalizado!';
      } else if (nuevoEstado == 'cancelada') {
        mensaje = '❌ La cita ha sido cancelada.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.secondary,
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

  // Colores semánticos por estado (se mantienen distintos entre sí
  // a propósito, para diferenciar estados de un vistazo).
  Color _obtenerColorEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return AppColors.secondary;
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return AppColors.muted;
    }
  }

  String _obtenerNombreUsuario(dynamic cita) {
    final usuario = cita['usuarioId'];
    if (usuario is Map) {
      final nombre = usuario['nombres'] ?? usuario['Nombre'];
      final apellido = usuario['apellidos'] ?? usuario['Apellido'];
      if (nombre != null && nombre.toString().trim().isNotEmpty) {
        final apellidoStr = (apellido != null && apellido.toString().trim().isNotEmpty)
            ? ' $apellido'
            : '';
        return '$nombre$apellidoStr';
      }
    }
    return 'Cliente sin nombre';
  }

  String _obtenerDetalleVehiculo(dynamic cita) {
    if (cita['vehiculoId'] is Map) {
      final v = cita['vehiculoId'];
      return '${v['placa'] ?? ''} - ${v['marca'] ?? ''} ${v['modelo'] ?? ''}'.trim();
    }
    return cita['vehiculo'] ?? cita['vehiculoId'] ?? 'N/A';
  }

  String _obtenerDetalleServicio(dynamic cita) {
    if (cita['servicioId'] is Map) {
      return cita['servicioId']['nombre'] ?? 'Servicio Estándar';
    }
    return cita['servicio'] ?? 'Servicio General';
  }

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
        // Sin backgroundColor propio: hereda el AppBarTheme global.
      ),
      backgroundColor: AppColors.background,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: _cargarCitas,
              child: _citas.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Text('No hay citas registradas.', style: AppTextStyles.body),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _citas.length,
                      itemBuilder: (context, index) {
                        final cita = _citas[index];
                        final estadoActual = cita['estado'] ?? 'pendiente';
                        final citaId = cita['_id'] ?? cita['id'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
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
                                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusChip(
                                      label: estadoActual,
                                      color: _obtenerColorEstado(estadoActual),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('🧼 Servicio: ${_obtenerDetalleServicio(cita)}', style: AppTextStyles.body),
                                Text('🚗 Vehículo: ${_obtenerDetalleVehiculo(cita)}', style: AppTextStyles.body),
                                Text(
                                  '📅 Fecha: ${_formatearFecha(cita['fechaHoraCita'], cita['hora'])}',
                                  style: AppTextStyles.body,
                                ),
                                if (cita['modalidad'] != null)
                                  Text(
                                    '📍 Modalidad: ${cita['modalidad'] == 'domicilio' ? 'A Domicilio' : 'En Spa'}',
                                    style: AppTextStyles.body,
                                  ),
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
                                          value: 'en_proceso',
                                          child: Row(
                                            children: [
                                              Icon(Icons.play_arrow, color: AppColors.secondary),
                                              SizedBox(width: 8),
                                              Text('Iniciar Lavada (En Proceso)'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'finalizada',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Finalizar Lavada (Completado)'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'cancelada',
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
                                          color: AppColors.primary,
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
                                            Icon(Icons.arrow_drop_down, color: AppColors.accent),
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