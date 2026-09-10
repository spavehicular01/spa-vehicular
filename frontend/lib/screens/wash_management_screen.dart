import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/socket_service.dart';
import '../services/wash_service.dart';
import '../main.dart'; // routeObserver

class WashManagementScreen extends StatefulWidget {
  const WashManagementScreen({super.key});

  @override
  State<WashManagementScreen> createState() => _WashManagementScreenState();
}

class _WashManagementScreenState extends State<WashManagementScreen>
    with RouteAware {
  final SocketService _socketService = SocketService();
  List<dynamic> _citas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCitasCliente();
    _iniciarEscuchaSockets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  // Se llama automáticamente cuando esta pantalla vuelve a quedar visible
  // (ej. al volver de BookingScreen tras agendar).
  @override
  void didPopNext() {
    _cargarCitasCliente();
  }

  // 🟢 NUEVO: obtiene el id del usuario desde la sesión guardada por
  // guardarSesionUsuario() en main.dart (clave 'usuario', JSON completo).
  Future<String?> _obtenerUsuarioIdGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioStr = prefs.getString('usuario');

    if (usuarioStr == null || usuarioStr.isEmpty) return null;

    try {
      final usuario = jsonDecode(usuarioStr) as Map<String, dynamic>;
      return usuario['id']?.toString() ?? usuario['_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cargarCitasCliente() async {
    if (mounted) setState(() => _cargando = true);

    try {
      final usuarioId = await _obtenerUsuarioIdGuardado();

      if (usuarioId != null && usuarioId.isNotEmpty) {
        final citas = await WashApiService.getCitasPorUsuario(usuarioId);
        if (mounted) {
          setState(() {
            _citas = citas;
            _cargando = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _citas = [];
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _iniciarEscuchaSockets() {
    _socketService.conectar((data) {
      if (!mounted) return;

      final String citaId = data['citaId'];
      final String nuevoEstado = data['nuevoEstado'];

      setState(() {
        final index = _citas.indexWhere((c) => c['_id'] == citaId);
        if (index != -1) {
          _citas[index]['estado'] = nuevoEstado;
        }
      });

      final estadoLower = nuevoEstado.toLowerCase();
      String mensajeSnackBar = '';
      if (estadoLower == 'en_proceso') {
        mensajeSnackBar = '🧼 ¡Atención! Tu servicio de lavado ha comenzado.';
      } else if (estadoLower == 'finalizada') {
        mensajeSnackBar = '✅ ¡Tu vehículo está listo! Revisa la pestaña Historial.';
      }

      if (mensajeSnackBar.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeSnackBar),
            backgroundColor: estadoLower == 'finalizada' ? Colors.green : Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _socketService.desconectar();
    super.dispose();
  }

  // Colores y etiquetas legibles para los valores reales del enum del schema:
  // ['pendiente', 'confirmada', 'en_proceso', 'finalizada', 'cancelada', 'reprogramada']
  Color _obtenerColorEstado(String? estado) {
    switch ((estado ?? '').toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.indigo;
      case 'en_proceso':
        return Colors.blue;
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'reprogramada':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _obtenerEtiquetaEstado(String? estado) {
    switch ((estado ?? '').toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'en_proceso':
        return 'En Proceso';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada':
        return 'Cancelada';
      case 'reprogramada':
        return 'Reprogramada';
      default:
        return estado ?? 'Pendiente';
    }
  }

  String _obtenerNombreServicio(Map<String, dynamic> cita) {
    if (cita['servicioNombre'] != null && cita['servicioNombre'].toString().isNotEmpty) {
      return cita['servicioNombre'];
    }
    if (cita['servicio'] is Map) {
      return cita['servicio']['nombreServicio'] ?? cita['servicio']['nombre'] ?? 'Servicio de Lavado';
    }
    if (cita['servicioId'] is Map) {
      return cita['servicioId']['nombreServicio'] ?? cita['servicioId']['nombre'] ?? 'Servicio de Lavado';
    }
    return 'Servicio de Lavado';
  }

  String _obtenerDescripcionServicio(Map<String, dynamic> cita) {
    if (cita['servicioDescripcion'] != null && cita['servicioDescripcion'].toString().isNotEmpty) {
      return cita['servicioDescripcion'];
    }
    if (cita['servicio'] is Map && cita['servicio']['descripcion'] != null) {
      return cita['servicio']['descripcion'];
    }
    if (cita['servicioId'] is Map && cita['servicioId']['descripcion'] != null) {
      return cita['servicioId']['descripcion'];
    }
    return 'Sin descripción registrada';
  }

  Widget _buildListaCitas(List<dynamic> citas, {required bool esHistorial}) {
    if (citas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarCitasCliente,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  esHistorial ? 'No tienes lavadas en tu historial.' : 'No tienes citas activas.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarCitasCliente,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: citas.length,
        itemBuilder: (context, index) {
          final cita = citas[index];
          final String estado = (cita['estado'] ?? 'pendiente').toString();
          final bool enProceso = estado.toLowerCase() == 'en_proceso';

          final String nombreServicio = _obtenerNombreServicio(cita);
          final String descripcionServicio = _obtenerDescripcionServicio(cita);

          return Card(
            elevation: enProceso ? 4 : 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: enProceso
                  ? const BorderSide(color: Colors.blue, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          nombreServicio,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _obtenerColorEstado(estado).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _obtenerColorEstado(estado)),
                        ),
                        child: Text(
                          _obtenerEtiquetaEstado(estado),
                          style: TextStyle(
                            color: _obtenerColorEstado(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcionServicio,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text('📅 Fecha/Hora: ${cita['fechaHoraCita'] ?? 'N/A'}'),
                  if (enProceso) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_car_wash, color: Colors.blue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¡Tu vehículo se encuentra actualmente en proceso de lavado!',
                              style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtros con los valores REALES del enum del schema de Appointment:
    // ['pendiente', 'confirmada', 'en_proceso', 'finalizada', 'cancelada', 'reprogramada']
    final citasActivas = _citas.where((c) {
  final estado = (c['estado'] ?? '').toString().toLowerCase();
  return estado == 'pendiente' ||
      estado == 'confirmada' ||
      estado == 'en_proceso' ||
      estado == 'reprogramada'; // 🟢 agregada aquí
}).toList();

final citasHistorial = _citas.where((c) {
  final estado = (c['estado'] ?? '').toString().toLowerCase();
  return estado == 'finalizada' || estado == 'cancelada';
}).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: const Color.fromARGB(255, 30, 0, 255),
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Color.fromARGB(179, 255, 251, 0),
              tabs: [
                Tab(icon: Icon(Icons.time_to_leave), text: 'En Curso / Próximas'),
                Tab(icon: Icon(Icons.history), text: 'Historial'),
              ],
            ),
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildListaCitas(citasActivas, esHistorial: false),
                  _buildListaCitas(citasHistorial, esHistorial: true),
                ],
              ),
      ),
    );
  }
}