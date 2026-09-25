import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/socket_service.dart';
import '../services/wash_service.dart';
import '../main.dart'; // routeObserver
import '../theme/app_theme.dart';

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

  @override
  void didPopNext() {
    _cargarCitasCliente();
  }

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
            backgroundColor: estadoLower == 'finalizada' ? Colors.green : AppColors.secondary,
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

  // Colores semánticos por estado (no son colores de marca, son de estatus,
  // así que se mantienen distintos entre sí para diferenciarlos de un vistazo).
  Color _obtenerColorEstado(String? estado) {
    switch ((estado ?? '').toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.indigo;
      case 'en_proceso':
        return AppColors.secondary;
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'reprogramada':
        return Colors.purple;
      default:
        return AppColors.muted;
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
        color: AppColors.secondary,
        onRefresh: _cargarCitasCliente,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esHistorial ? Icons.history : Icons.event_available_outlined,
                      color: AppColors.muted,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      esHistorial ? 'No tienes lavadas en tu historial.' : 'No tienes citas activas.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.secondary,
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
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: enProceso
                  ? const BorderSide(color: AppColors.secondary, width: 1.5)
                  : BorderSide(color: Colors.grey.shade200),
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
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: _obtenerEtiquetaEstado(estado),
                        color: _obtenerColorEstado(estado),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcionServicio,
                    style: AppTextStyles.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '📅 Fecha/Hora: ${cita['fechaHoraCita'] ?? 'N/A'}',
                    style: AppTextStyles.labelMuted.copyWith(letterSpacing: 0, fontSize: 12),
                  ),
                  if (enProceso) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x1A00E5FF), // accent al 10%
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_car_wash, color: AppColors.secondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¡Tu vehículo se encuentra actualmente en proceso de lavado!',
                              style: TextStyle(
                                color: AppColors.secondary,
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
    final citasActivas = _citas.where((c) {
      final estado = (c['estado'] ?? '').toString().toLowerCase();
      return estado == 'pendiente' ||
          estado == 'confirmada' ||
          estado == 'en_proceso' ||
          estado == 'reprogramada';
    }).toList();

    final citasHistorial = _citas.where((c) {
      final estado = (c['estado'] ?? '').toString().toLowerCase();
      return estado == 'finalizada' || estado == 'cancelada';
    }).toList();

    // Sin Scaffold propio: esta pantalla vive dentro de MainNavigationScreen
    // (tab "Lavadas"), que ya provee el Scaffold y el AppBar "Mis Lavadas".
    // El TabBar de aquí abajo es parte del body, no una segunda barra.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: const TabBar(
              indicatorColor: AppColors.accent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(icon: Icon(Icons.time_to_leave), text: 'En Curso / Próximas'),
                Tab(icon: Icon(Icons.history), text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : TabBarView(
                    children: [
                      _buildListaCitas(citasActivas, esHistorial: false),
                      _buildListaCitas(citasHistorial, esHistorial: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}