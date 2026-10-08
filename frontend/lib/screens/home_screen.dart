import 'package:flutter/material.dart';
import '../widgets/auth_required_dialog.dart';
import '../widgets/home/accesos_rapidos.dart';
import '../widgets/home/home_data.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/opiniones_carrusel.dart';
import '../widgets/home/por_que_elegirnos_card.dart';
import '../widgets/home/proxima_cita_card.dart';
import '../widgets/home/seccion_titulo.dart';
import '../widgets/home/ubicacion_card.dart';
import '../services/wash_service.dart';
import 'services_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioAutenticado;
  final void Function(Map<String, dynamic> datos)? onLoginExitoso;

  /// Cambia de pestaña en MainNavigationScreen:
  /// 0 Inicio, 1 Calendario, 2 Lavadas, 3 Perfil.
  final void Function(int indice)? onIrATab;

  const HomeScreen({
    super.key,
    this.usuarioAutenticado,
    this.onLoginExitoso,
    this.onIrATab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _proximaCita;
  bool _cargandoCita = false;

  String? get _usuarioId => (widget.usuarioAutenticado?['id'] ??
          widget.usuarioAutenticado?['_id'])
      ?.toString();

  @override
  void initState() {
    super.initState();
    _cargarProximaCita();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idAnterior = (oldWidget.usuarioAutenticado?['id'] ??
            oldWidget.usuarioAutenticado?['_id'])
        ?.toString();
    if (idAnterior != _usuarioId) _cargarProximaCita();
  }

  Future<void> _cargarProximaCita() async {
    final id = _usuarioId;
    if (id == null || id.isEmpty) {
      if (mounted) {
        setState(() {
          _proximaCita = null;
          _cargandoCita = false;
        });
      }
      return;
    }

    setState(() => _cargandoCita = true);
    try {
      final citas = await WashApiService.getCitasPorUsuario(id);
      final activas = citas.where((c) {
        final e = (c['estado'] ?? '').toString().toLowerCase();
        return e == 'pendiente' ||
            e == 'confirmada' ||
            e == 'en_proceso' ||
            e == 'reprogramada';
      }).toList();

      activas.sort((a, b) {
        final da = DateTime.tryParse('${a['fechaHoraCita']}');
        final db = DateTime.tryParse('${b['fechaHoraCita']}');
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      if (!mounted) return;
      setState(() {
        _proximaCita = activas.isEmpty
            ? null
            : Map<String, dynamic>.from(activas.first as Map);
        _cargandoCita = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _proximaCita = null;
        _cargandoCita = false;
      });
    }
  }

  // ───────────── Acciones ─────────────

  void _conSesion(VoidCallback accion) {
    if (widget.usuarioAutenticado == null) {
      AuthRequiredDialog.show(
        context,
        onLoginExitoso: (datos) {
          widget.onLoginExitoso?.call(datos);
          accion();
        },
      );
      return;
    }
    accion();
  }

  void _irAServicios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServicesScreen()),
    );
  }

  // ───────────── Build ─────────────

  @override
  Widget build(BuildContext context) {
    // Sin Scaffold/AppBar propios a propósito: esta pantalla vive dentro de
    // MainNavigationScreen, que ya provee el Scaffold y el AppBar.
    final sinAnimacion = MediaQuery.of(context).disableAnimations;

    // Única animación de entrada de la pantalla (una sola, no por sección).
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: sinAnimacion ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(
              usuario: widget.usuarioAutenticado,
              onIniciarSesion: () => widget.onIrATab?.call(3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SeccionTitulo('Tu próxima lavada'),
                  ProximaCitaCard(
                    cargando: _cargandoCita,
                    cita: _proximaCita,
                    logueado: widget.usuarioAutenticado != null,
                    onIrATab: widget.onIrATab,
                  ),
                  const SizedBox(height: 28),
                  const SeccionTitulo('Accesos rápidos'),
                  AccesosRapidos(
                    onServicios: () => _conSesion(_irAServicios),
                    onAgendar: () => widget.onIrATab?.call(1),
                    onVehiculos: () => widget.onIrATab?.call(3),
                    onLavadas: () => widget.onIrATab?.call(2),
                  ),
                  const SizedBox(height: 28),
                  const SeccionTitulo('Por qué elegirnos'),
                  const PorQueElegirnosCard(),
                  const SizedBox(height: 28),
                  const SeccionTitulo('Horario y ubicación'),
                  const UbicacionCard(),
                  const SizedBox(height: 28),
                  const SeccionTitulo('Opiniones de clientes'),
                  const OpinionesCarrusel(opiniones: kOpiniones),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
