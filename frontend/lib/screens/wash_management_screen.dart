import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/socket_service.dart';
import '../services/wash_service.dart';
import '../main.dart'; // routeObserver
import '../theme/app_theme.dart';
import '../widgets/wash/citas_list.dart';
import '../widgets/wash/citas_skeleton_list.dart';

class WashManagementScreen extends StatefulWidget {
  /// Se llama desde el estado vacío ("Agendar cita") para ir al calendario.
  final VoidCallback? onAgendar;

  const WashManagementScreen({super.key, this.onAgendar});

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

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _socketService.desconectar();
    super.dispose();
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
      if (mounted) setState(() => _cargando = false);
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
      String mensaje = '';
      if (estadoLower == 'en_proceso') {
        mensaje = '🧼 ¡Atención! Tu servicio de lavado ha comenzado.';
      } else if (estadoLower == 'finalizada') {
        mensaje = '✅ ¡Tu vehículo está listo! Revisa la pestaña Historial.';
      }

      if (mensaje.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor:
                estadoLower == 'finalizada' ? Colors.green : AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  bool _esActiva(dynamic c) {
    final estado = (c['estado'] ?? '').toString().toLowerCase();
    return estado == 'pendiente' ||
        estado == 'confirmada' ||
        estado == 'en_proceso' ||
        estado == 'reprogramada';
  }

  bool _esHistorial(dynamic c) {
    final estado = (c['estado'] ?? '').toString().toLowerCase();
    return estado == 'finalizada' || estado == 'cancelada';
  }

  @override
  Widget build(BuildContext context) {
    final citasActivas = _citas.where(_esActiva).toList();
    final citasHistorial = _citas.where(_esHistorial).toList();

    // Sin Scaffold propio: vive dentro de MainNavigationScreen (tab "Lavadas").
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
                ? const CitasSkeletonList()
                : TabBarView(
                    children: [
                      CitasList(
                        citas: citasActivas,
                        esHistorial: false,
                        onRefresh: _cargarCitasCliente,
                        onAgendar: widget.onAgendar,
                      ),
                      CitasList(
                        citas: citasHistorial,
                        esHistorial: true,
                        onRefresh: _cargarCitasCliente,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}