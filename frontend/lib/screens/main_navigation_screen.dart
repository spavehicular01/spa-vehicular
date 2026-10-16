import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/session_guard.dart';
import '../services/socket_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'wash_management_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'notifications_screen.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../widgets/extras/ui_extras.dart';
import '../main.dart'; // 🟢 usuarioActualNotifier, guardarSesionUsuario, cerrarSesionUsuario


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SessionGuard.sesionExpirada.addListener(_alExpirarSesion);
  }

  @override
  void dispose() {
    SessionGuard.sesionExpirada.removeListener(_alExpirarSesion);
    super.dispose();
  }

  /// 🟢 El servidor rechazó el token (venció o se cambió la clave): se cierra la
  /// sesión y se manda al login en lugar de dejar pantallas vacías con errores.
  void _alExpirarSesion() {
    if (!mounted || usuarioActualNotifier.value == null) return;

    cerrarSesionUsuario();
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    setState(() => _selectedIndex = 3);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu sesión venció. Inicia sesión de nuevo.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _irATab(int indice) => setState(() => _selectedIndex = indice);

  void _abrirChatAsesor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatBottomSheet(),
    );
  }

  Widget _buildVistaBloqueada(String titulo, String descripcion) {
    return EmptyState(
      icono: Icons.lock_outline,
      titulo: titulo,
      mensaje: descripcion,
      textoBoton: 'Ir a Iniciar Sesión',
      onPressed: () => _irATab(3),
    );
  }

  Widget _getPage(int index, Map<String, dynamic>? usuarioAutenticado) {
    switch (index) {
      case 0:
        return HomeScreen(
          usuarioAutenticado: usuarioAutenticado,
          onLoginExitoso: (datos) {
            guardarSesionUsuario(datos);
            guardarSesionUsuario(datos);
          },
          onIrATab: _irATab,
        );
      case 1:
        if (usuarioAutenticado == null) {
          return _buildVistaBloqueada(
            'Agendar Citas',
            'Debes iniciar sesión para agendar citas para tu vehículo.',
          );
        }
        return CalendarScreen(
          usuario: usuarioAutenticado,
          token: usuarioAutenticado['token'],
          onLoginExitoso: (datos) {
            guardarSesionUsuario(datos);
            guardarSesionUsuario(datos);
          },
        );
      case 2:
        if (usuarioAutenticado == null) {
          return _buildVistaBloqueada(
            'Mis Lavadas e Historial',
            'Debes iniciar sesión para ver tus citas agendadas y el historial.',
          );
        }
        return WashManagementScreen(onAgendar: () => _irATab(1));
      case 3:
        if (usuarioAutenticado == null) {
          return LoginScreen(
            onLoginExitoso: (datos) {
              guardarSesionUsuario(datos);
              guardarSesionUsuario(datos);
            },
          );
        } else if (usuarioAutenticado['rol'] == 'admin') {
          return AdminDashboardScreen(
            userData: usuarioAutenticado,
            onCerrarSesion: () {
              cerrarSesionUsuario();
              cerrarSesionUsuario();
              setState(() => _selectedIndex = 0);
            },
          );
        } else {
          return ProfileScreen(
            nombreCompleto: usuarioAutenticado['nombres'] ?? '',
            correo: usuarioAutenticado['correo'] ?? '',
            documento: usuarioAutenticado['documento'] ?? '',
            telefono: usuarioAutenticado['telefono'] ?? '',
            vehiculos: ((usuarioAutenticado['vehiculos'] ?? []) as List)
                .map<Map<String, String>>(
                  (v) => Map<String, dynamic>.from(v).map(
                    (key, value) => MapEntry(key, value?.toString() ?? ''),
                  ),
                )
                .toList(),
            onVehiculosChanged: (nuevosVehiculos) {
              final actualizado = Map<String, dynamic>.from(usuarioAutenticado);
              actualizado['vehiculos'] = nuevosVehiculos;
              guardarSesionUsuario(actualizado);
            },
            onCerrarSesion: () {
              cerrarSesionUsuario();
              cerrarSesionUsuario();
              setState(() => _selectedIndex = 0);
            },
          );
        }
      default:
        return HomeScreen(
          usuarioAutenticado: usuarioAutenticado,
          onIrATab: _irATab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: usuarioActualNotifier,
      builder: (context, usuarioAutenticado, _) {
        return Scaffold(
          // Único AppBar de toda la navegación principal: las pantallas hijas
          // (HomeScreen, etc.) NO deben traer su propio AppBar, o se duplica.
          appBar: AppBar(
            title: Text(
              ['Spa Vehicular', 'Calendario', 'Mis Lavadas', 'Cuenta'][_selectedIndex],
            ),
            actions: [
              // 🟢 Campana de notificaciones (solo con sesión iniciada)
              if (usuarioAutenticado != null)
                _CampanaNotificaciones(
                  key: ValueKey(
                    (usuarioAutenticado['id'] ?? usuarioAutenticado['_id']).toString(),
                  ),
                  usuario: usuarioAutenticado,
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen(usuario: usuarioAutenticado),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _getPage(_selectedIndex, usuarioAutenticado),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_btn_asesor_chat',
            elevation: 4,
            shape: const CircleBorder(),
            tooltip: 'Consultar al Asesor Virtual',
            onPressed: _abrirChatAsesor,
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          // FAB integrado en la barra (con muesca central).
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).cardColor,
            surfaceTintColor: Colors.transparent,
            elevation: 8,
            height: 68,
            padding: EdgeInsets.zero,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icono: Icons.home_outlined,
                    iconoActivo: Icons.home,
                    etiqueta: 'Inicio',
                    seleccionado: _selectedIndex == 0,
                    onTap: () => _irATab(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icono: Icons.calendar_month_outlined,
                    iconoActivo: Icons.calendar_month,
                    etiqueta: 'Calendario',
                    seleccionado: _selectedIndex == 1,
                    onTap: () => _irATab(1),
                  ),
                ),
                const SizedBox(width: 72), // espacio para el FAB
                Expanded(
                  child: _NavItem(
                    icono: Icons.local_car_wash_outlined,
                    iconoActivo: Icons.local_car_wash,
                    etiqueta: 'Lavadas',
                    seleccionado: _selectedIndex == 2,
                    onTap: () => _irATab(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icono: Icons.person_outline,
                    iconoActivo: Icons.person,
                    etiqueta: 'Perfil',
                    seleccionado: _selectedIndex == 3,
                    onTap: () => _irATab(3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🟢 Campana del AppBar con el contador de notificaciones sin leer.
/// Consulta el servidor al abrirse y cada 30 segundos, y al volver de la lista.
class _CampanaNotificaciones extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const _CampanaNotificaciones({super.key, required this.usuario});

  @override
  State<_CampanaNotificaciones> createState() => _CampanaNotificacionesState();
}

class _CampanaNotificacionesState extends State<_CampanaNotificaciones> {
  int _noLeidas = 0;
  Timer? _timer;
  final SocketService _socket = SocketService();

  String? get _usuarioId =>
      (widget.usuario['id'] ?? widget.usuario['_id'])?.toString();

  @override
  void initState() {
    super.initState();
    _cargarContador();

    // 🟢 Tiempo real: cuando llega una notificación nueva, el contador se actualiza al instante.
    _socket.conectar(null, onNuevaNotificacion: (_) => _cargarContador());

    // Respaldo por si se cae la conexión en tiempo real
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _cargarContador());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket.desconectar();
    super.dispose();
  }

  Future<void> _cargarContador() async {
    final id = _usuarioId;
    if (id == null || id.isEmpty) return;

    try {
      final lista = await ApiService.obtenerNotificaciones(id);
      final cantidad = lista.where((n) => n['leida'] != true).length;
      if (!mounted) return;
      setState(() => _noLeidas = cantidad);
    } catch (_) {
      // Sin conexión o sesión vencida: se conserva el último valor
    }
  }

  Future<void> _abrirNotificaciones() async {
    final id = _usuarioId;
    if (id == null || id.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationsScreen(usuarioId: id)),
    );

    // Al volver, se actualiza el contador (pudo marcar algunas como leídas)
    _cargarContador();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications),
          onPressed: _abrirNotificaciones,
        ),
        if (_noLeidas > 0)
          Positioned(
            right: 6,
            top: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _noLeidas > 9 ? '9+' : '$_noLeidas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ítem de la barra inferior con "píldora" cian suave cuando está activo.
class _NavItem extends StatelessWidget {
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _NavItem({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = colorAcento(context);
    final color = seleccionado ? activo : AppColors.muted;

    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: seleccionado
                  ? AppColors.accent.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(seleccionado ? iconoActivo : icono, size: 24, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}