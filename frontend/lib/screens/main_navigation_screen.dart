import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'wash_management_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../main.dart'; // 🟢 usuarioActualNotifier, guardarSesionUsuario, cerrarSesionUsuario

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // 🔴 ELIMINADO: Map<String, dynamic>? _usuarioAutenticado;
  // Ya no existe estado local de usuario. Toda la app lee/escribe
  // usuarioActualNotifier (definido en main.dart), así que sin importar
  // desde dónde se dispare el login (diálogo "Atención", tab Perfil,
  // AuthRequiredDialog en Calendario, etc.) el estado queda sincronizado
  // en toda la aplicación, incluso si esta pantalla se reconstruye.

  void _abrirChatAsesor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatBottomSheet(),
    );
  }

  Widget _buildVistaBloqueada(String titulo, String descripcion) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Color.fromARGB(255, 0, 34, 255)),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _selectedIndex = 3),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 34, 255),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Iniciar Sesión'),
          )
        ],
      ),
    );
  }

  Widget _getPage(int index, Map<String, dynamic>? usuarioAutenticado) {
    switch (index) {
      case 0:
        return HomeScreen(
          usuarioAutenticado: usuarioAutenticado,
          onLoginExitoso: (datos) {
            guardarSesionUsuario(datos); // 🟢 antes: setState local
          },
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
            guardarSesionUsuario(datos); // 🟢 antes: setState local
          },
        );
      case 2:
        if (usuarioAutenticado == null) {
          return _buildVistaBloqueada(
            'Mis Lavadas e Historial',
            'Debes iniciar sesión para ver tus citas agendadas y el historial.',
          );
        }
        return const WashManagementScreen();
      case 3:
        if (usuarioAutenticado == null) {
          return LoginScreen(
            onLoginExitoso: (datos) {
              guardarSesionUsuario(datos); // 🟢 antes: setState local
            },
          );
        } else if (usuarioAutenticado['rol'] == 'admin') {
          return AdminDashboardScreen(
            userData: usuarioAutenticado,
            onCerrarSesion: () {
              cerrarSesionUsuario(); // 🟢 antes: setState local
              setState(() => _selectedIndex = 0);
            },
          );
        } else {
          return ProfileScreen(
            nombreCompleto: usuarioAutenticado['nombres'] ?? '',
            correo: usuarioAutenticado['correo'] ?? '',
            documento: usuarioAutenticado['documento'] ?? '',
            telefono: usuarioAutenticado['telefono'] ?? '',
            vehiculos: List<Map<String, String>>.from(
              usuarioAutenticado['vehiculos'] ?? [],
            ),
            onVehiculosChanged: (nuevosVehiculos) {
              // 🟢 Actualiza el mapa y vuelve a guardar la sesión completa
              final actualizado = Map<String, dynamic>.from(usuarioAutenticado);
              actualizado['vehiculos'] = nuevosVehiculos;
              guardarSesionUsuario(actualizado);
            },
            onCerrarSesion: () {
              cerrarSesionUsuario(); // 🟢 antes: setState local
              setState(() => _selectedIndex = 0);
            },
          );
        }
      default:
        return HomeScreen(usuarioAutenticado: usuarioAutenticado);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 ValueListenableBuilder: reconstruye automáticamente esta pantalla
    // (y por lo tanto Calendar/Home/Profile) cada vez que
    // usuarioActualNotifier cambie, sin importar desde dónde se
    // haya disparado el login o logout.
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: usuarioActualNotifier,
      builder: (context, usuarioAutenticado, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              ['Spa Vehicular', 'Calendario', 'Mis Lavadas', 'Cuenta'][_selectedIndex],
            ),
            backgroundColor: const Color.fromARGB(255, 0, 30, 255),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _getPage(_selectedIndex, usuarioAutenticado),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_btn_asesor_chat',
            backgroundColor: const Color.fromARGB(255, 0, 34, 255),
            elevation: 4,
            shape: const CircleBorder(),
            tooltip: 'Consultar al Asesor Virtual',
            onPressed: _abrirChatAsesor,
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromARGB(255, 0, 34, 255),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Calendario',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_car_wash),
                label: 'Lavadas',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }
}