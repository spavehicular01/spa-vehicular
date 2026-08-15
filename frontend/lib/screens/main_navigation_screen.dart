import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'wash_management_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Estado simulado de usuario (Luego lo conectaremos a la BD)
  final bool _isLoggedIn = false; 

  final List<Widget> _pages = const [
    HomeScreen(),
    CalendarScreen(),
    WashManagementScreen(),
    LoginScreen(),
  ];

  final List<String> _titles = const [
    'Spa Vehicular',
    'Calendario',
    'Mis Lavadas',
    'Cuenta',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Icono/Foto de Perfil (Si está registrado)
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  // Acción al hacer tap en perfil
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                ),
              ),
            ),
          // Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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