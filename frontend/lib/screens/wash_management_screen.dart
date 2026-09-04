import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
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
            backgroundColor: nuevoEstado == 'Completado' ? Colors.green : AppTheme.azulElectrico,
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
        return AppTheme.azulElectrico;
      case 'Completado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildListaCitas(List<dynamic> citas, {required bool esHistorial}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (citas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarCitasCliente,
        color: AppTheme.azulElectrico,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  esHistorial ? 'No tienes lavadas en tu historial.' : 'No tienes citas activas.',
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarCitasCliente,
      color: AppTheme.azulElectrico,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: citas.length,
        itemBuilder: (context, index) {
          final cita = citas[index];
          final String estado = cita['estado'] ?? 'Pendiente';
          final bool enProceso = estado == 'En Proceso';

          final Color accentColor = _obtenerColorEstado(estado);

          return Card(
            elevation: enProceso ? 4 : 2,
            color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: enProceso
                  ? BorderSide(color: isDark ? const Color(0xFF60A5FA) : AppTheme.azulElectrico, width: 2)
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
                      Expanded(
                        child: Text(
                          cita['servicioNombre'] ?? 'Servicio de Lavado',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark && accentColor == AppTheme.azulElectrico 
                                  ? const Color(0xFF60A5FA) 
                                  : accentColor).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark && accentColor == AppTheme.azulElectrico 
                                ? const Color(0xFF60A5FA) 
                                : accentColor,
                          ),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: isDark && accentColor == AppTheme.azulElectrico 
                                ? const Color(0xFF60A5FA) 
                                : accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📅 Fecha/Hora: ${cita['fechaHoraCita'] ?? 'N/A'}',
                    style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87),
                  ),
                  if (enProceso) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3B82F6) : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_car_wash, 
                            color: isDark ? const Color(0xFF60A5FA) : AppTheme.azulElectrico,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¡Tu vehículo se encuentra actualmente en proceso de lavado!',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF93C5FD) : AppTheme.azulElectrico, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                              ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final citasActivas = _citas
        .where((c) => c['estado'] == 'Pendiente' || c['estado'] == 'En Proceso')
        .toList();

    final citasHistorial = _citas
        .where((c) => c['estado'] == 'Completado' || c['estado'] == 'Cancelado')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : AppTheme.azulElectrico,
            child: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.time_to_leave), text: 'En Curso / Próximas'),
                Tab(icon: Icon(Icons.history), text: 'Historial'),
              ],
            ),
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppTheme.azulElectrico))
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