import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _token;
  bool _cargandoSesion = true;

  @override
  void initState() {
    super.initState();
    _cargarSesionPersistida();
  }

  // Carga el usuario y el token guardados localmente al iniciar la app
  Future<void> _cargarSesionPersistida() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userString = prefs.getString('user_data');
    final String? tokenGuardado = prefs.getString('token');

    if (userString != null && userString.isNotEmpty) {
      final Map<String, dynamic> userMap = jsonDecode(userString);

      // Normalizar identificador para garantizar que 'id' y '_id' existan
      final String? idNormalizado = userMap['id'] ?? userMap['_id'];
      if (idNormalizado != null) {
        userMap['id'] = idNormalizado;
        userMap['_id'] = idNormalizado;
      }

      setState(() {
        _usuarioAutenticado = userMap;
        _token = tokenGuardado;
      });
    }

    setState(() {
      _cargandoSesion = false;
    });
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

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        if (_usuarioAutenticado == null) {
          return _buildVistaBloqueada(
            'Agendar Citas',
            'Debes iniciar sesión para agendar citas para tu vehículo.',
          );
        }
        return CalendarScreen(
          usuario: _usuarioAutenticado,
          token: _token,
        );
      case 2:
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
            onLoginExitoso: (datos) async {
              Map<String, dynamic> usuario = Map<String, dynamic>.from(
                datos['usuario'] ?? datos,
              );
              final token = datos['token'];

              final String? userId = datos['id'] ??
                  datos['_id'] ??
                  usuario['id'] ??
                  usuario['_id'];

              if (userId != null) {
                usuario['id'] = userId;
                usuario['_id'] = userId;
              }

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_data', jsonEncode(usuario));
              if (token != null) {
                await prefs.setString('token', token);
              }

              setState(() {
                _usuarioAutenticado = usuario;
                _token = token;
              });
            },
          );
        } else if (_usuarioAutenticado!['rol'] == 'admin') {
          return AdminDashboardScreen(
            userData: _usuarioAutenticado!,
            onCerrarSesion: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_data');
              await prefs.remove('token');

              setState(() {
                _usuarioAutenticado = null;
                _token = null;
                _selectedIndex = 0;
              });
            },
          );
        } else {
          return ProfileScreen(
            nombreCompleto: _usuarioAutenticado!['nombres'] ?? _usuarioAutenticado!['nombre'] ?? '',
            correo: _usuarioAutenticado!['correo'] ?? _usuarioAutenticado!['email'] ?? '',
            documento: _usuarioAutenticado!['documento'] ?? _usuarioAutenticado!['cedula'] ?? '',
            telefono: _usuarioAutenticado!['celular'] ?? _usuarioAutenticado!['telefono'] ?? '',
            // Convierte los elementos de forma segura a Map<String, dynamic>
            vehiculos: List<Map<String, dynamic>>.from(
              (_usuarioAutenticado!['vehiculos'] as List? ?? []).map(
                (item) => Map<String, dynamic>.from(item as Map),
              ),
            ),
            onVehiculosChanged: (nuevosVehiculos) async {
              setState(() {
                _usuarioAutenticado!['vehiculos'] = nuevosVehiculos;
              });
              // Persistir cambios en SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_data', jsonEncode(_usuarioAutenticado));
            },
            onCerrarSesion: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_data');
              await prefs.remove('token');

              setState(() {
                _usuarioAutenticado = null;
                _token = null;
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
    if (_cargandoSesion) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                  builder: (context) => SettingsScreen(
                    usuario: _usuarioAutenticado,
                    onUsuarioActualizado: (usuarioActualizado) async {
                      if (usuarioActualizado.isEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('user_data');
                        await prefs.remove('token');

                        setState(() {
                          _usuarioAutenticado = null;
                          _token = null;
                        });
                      } else {
                        final String? userId = usuarioActualizado['id'] ?? usuarioActualizado['_id'];
                        if (userId != null) {
                          usuarioActualizado['id'] = userId;
                          usuarioActualizado['_id'] = userId;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_data', jsonEncode(usuarioActualizado));

                        setState(() {
                          _usuarioAutenticado = usuarioActualizado;
                        });
                      }
                    },
                  ),
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
        selectedItemColor: const Color.fromARGB(255, 0, 34, 255),
        unselectedItemColor: const Color.fromARGB(255, 158, 158, 158),
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