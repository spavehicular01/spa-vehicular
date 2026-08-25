import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import '../services/wash_service.dart';

class WashManagementScreen extends StatefulWidget {
  const WashManagementScreen({super.key});

  @override
  State<WashManagementScreen> createState() => _WashManagementScreenState();
}

class _WashManagementScreenState extends State<WashManagementScreen> {
  final SocketService _socketService = SocketService();
  List<dynamic> _citas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCitasCliente();
    _iniciarEscuchaSockets();
  }

  Future<void> _cargarCitasCliente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usuarioId = prefs.getString('userId');

      if (usuarioId != null && usuarioId.isNotEmpty) {
        final citas = await WashApiService.getCitasProgramadas();
        if (mounted) {
          setState(() {
            _citas = citas;
            _cargando = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _cargando = false);
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

      String mensajeSnackBar = '';
      if (nuevoEstado == 'En Proceso') {
        mensajeSnackBar = '🧼 ¡Atención! Tu servicio de lavado ha comenzado.';
      } else if (nuevoEstado == 'Completado') {
        mensajeSnackBar = '✅ ¡Tu vehículo está listo! Revisa la pestaña Historial.';
      }

      if (mensajeSnackBar.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeSnackBar),
            backgroundColor: nuevoEstado == 'Completado' ? Colors.green : Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _socketService.desconectar();
    super.dispose();
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
          final String estado = cita['estado'] ?? 'Pendiente';
          final bool enProceso = estado == 'En Proceso';

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
                    children: [
                      Text(
                        cita['servicioNombre'] ?? 'Servicio de Lavado',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _obtenerColorEstado(estado).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _obtenerColorEstado(estado)),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: _obtenerColorEstado(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
    final citasActivas = _citas
        .where((c) => c['estado'] == 'Pendiente' || c['estado'] == 'En Proceso')
        .toList();

    final citasHistorial = _citas
        .where((c) => c['estado'] == 'Completado' || c['estado'] == 'Cancelado')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.teal,
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
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