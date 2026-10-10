import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'wash_management_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';
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
