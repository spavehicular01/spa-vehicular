import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'wash_management_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _usuarioAutenticado;

  Widget _buildVistaBloqueada(String titulo, String descripcion) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.teal),
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
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Iniciar Sesión'),
          )
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        // Exige inicio de sesión para Calendario
        if (_usuarioAutenticado == null) {
          return _buildVistaBloqueada(
            'Agendar Citas',
            'Debes iniciar sesión para agendar citas para tu vehículo.',
          );
        }
        return const CalendarScreen();
      case 2:
        // Exige inicio de sesión para Lavadas / Historial
        if (_usuarioAutenticado == null) {
          return _buildVistaBloqueada(
            'Mis Lavadas e Historial',
            'Debes iniciar sesión para ver tus citas agendadas y el historial.',
          );
        }
        return const WashManagementScreen();
      case 3:
        if (_usuarioAutenticado == null) {
          return LoginScreen(
            onLoginExitoso: (datos) {
              setState(() {
                _usuarioAutenticado = datos;
              });
            },
          );
        } else if (_usuarioAutenticado!['rol'] == 'admin') {
          // Si el rol es Administrador, despliega el Panel Administrativo
          return AdminDashboardScreen(
            userData: _usuarioAutenticado!,
            onCerrarSesion: () {
              setState(() {
                _usuarioAutenticado = null;
                _selectedIndex = 0;
              });
            },
          );
        } else {
          // Si el rol es Cliente, despliega la pantalla de Perfil habitual
          return ProfileScreen(
            nombreCompleto: _usuarioAutenticado!['nombres'] ?? '',
            correo: _usuarioAutenticado!['correo'] ?? '',
            documento: _usuarioAutenticado!['documento'] ?? '',
            telefono: _usuarioAutenticado!['telefono'] ?? '',
            vehiculos: List<Map<String, String>>.from(
              _usuarioAutenticado!['vehiculos'] ?? [],
            ),
            onVehiculosChanged: (nuevosVehiculos) {
              setState(() {
                _usuarioAutenticado!['vehiculos'] = nuevosVehiculos;
              });
            },
            onCerrarSesion: () {
              setState(() {
                _usuarioAutenticado = null;
                _selectedIndex = 0;
              });
            },
          );
        }
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Spa Vehicular', 'Calendario', 'Mis Lavadas', 'Cuenta'][_selectedIndex],
        ),
        backgroundColor: Colors.teal,
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
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
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
  }
}