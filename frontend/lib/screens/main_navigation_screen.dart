import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'wash_management_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Estado dinámico del usuario autenticado (Si es null, no ha iniciado sesión)
  Map<String, String>? _usuarioAutenticado;

  final List<String> _titles = const [
    'Spa Vehicular',
    'Calendario',
    'Mis Lavadas',
    'Cuenta',
  ];

  // Construye dinámicamente las páginas
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CalendarScreen();
      case 2:
        return const WashManagementScreen();
      case 3:
        // Pestaña de Perfil / Cuenta
        if (_usuarioAutenticado == null) {
          // Muestra el Login si no está autenticado
          return LoginScreen(
            onLoginExitoso: (datos) {
              setState(() {
                _usuarioAutenticado = datos;
              });
            },
          );
        } else {
          // Muestra el Perfil si ya inició sesión
          return ProfileScreen(
            nombreCompleto: _usuarioAutenticado!['nombres'] ?? 'Usuario',
            correo: _usuarioAutenticado!['correo'] ?? '',
            documento: _usuarioAutenticado!['documento'] ?? 'Sin datos',
            telefono: _usuarioAutenticado!['telefono'] ?? 'Sin datos',
            onCerrarSesion: () {
              setState(() {
                _usuarioAutenticado = null;
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
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Icono / Avatar del Perfil (Solo si inició sesión)
          if (_usuarioAutenticado != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.shade200,
                child: Text(
                  _usuarioAutenticado!['nombres'] != null &&
                          _usuarioAutenticado!['nombres']!.isNotEmpty
                      ? _usuarioAutenticado!['nombres']![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Botón de Ajustes
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_car_wash),
            label: 'Lavadas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}