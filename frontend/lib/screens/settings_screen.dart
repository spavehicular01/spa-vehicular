import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Importante para acceder a los Notifier globales
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final Function(Map<String, dynamic>)? onUsuarioActualizado;

  const SettingsScreen({
    super.key, 
    this.usuario,
    this.onUsuarioActualizado,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _celularController;
  late TextEditingController _documentoController;

  bool _isLoading = false;
  File? _imagenSeleccionada;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  // Comprueba si existe una sesión activa
  bool get _estaAutenticado => widget.usuario != null && widget.usuario!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(
      text: widget.usuario?['nombres'] ?? widget.usuario?['nombre'] ?? '',
    );
    _apellidosController = TextEditingController(
      text: widget.usuario?['apellidos'] ?? '',
    );
    _celularController = TextEditingController(
      text: widget.usuario?['celular'] ?? widget.usuario?['telefono'] ?? '',
    );
    _documentoController = TextEditingController(
      text: widget.usuario?['documento'] ?? widget.usuario?['cedula'] ?? widget.usuario?['documentoIdentidad'] ?? 'Sin Documento',
    );
    _avatarUrl = widget.usuario?['avatar'] ?? widget.usuario?['imagenUrl'];
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _celularController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _cambiarModoOscuro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modo_oscuro', value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _cambiarTamanioLetra(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', value);
    fontSizeNotifier.value = value;
  }

  Future<void> _seleccionarFoto() async {
    if (!_estaAutenticado) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _imagenSeleccionada = File(image.path);
      });
    }
  }

  void _guardarCambios() async {
    final userId = widget.usuario?['id'] ?? widget.usuario?['_id'];

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el ID del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await UserService.actualizarPerfil(
      id: userId,
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      celular: _celularController.text.trim(),
      imagen: _imagenSeleccionada,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado['success'] == true && resultado['usuario'] != null) {
      final Map<String, dynamic> usuarioActualizado = Map<String, dynamic>.from(resultado['usuario']);

      setState(() {
        if (usuarioActualizado['avatar'] != null) {
          _avatarUrl = usuarioActualizado['avatar'];
        }
        _imagenSeleccionada = null;
      });

      // Guardar localmente para evitar desincronizaciones
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(usuarioActualizado));

      // Notificar al widget padre si existe el callback
      if (widget.onUsuarioActualizado != null) {
        widget.onUsuarioActualizado!(usuarioActualizado);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['message'] ?? 'Perfil actualizado'),
        backgroundColor: resultado['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_estaAutenticado ? 'Ajustes de Perfil' : 'Ajustes y Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SI ESTÁ AUTENTICADO: Se muestra la gestión del perfil
            if (_estaAutenticado) ...[
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                      backgroundImage: _imagenSeleccionada != null
                          ? FileImage(_imagenSeleccionada!)
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : null,
                      child: (_imagenSeleccionada == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 55, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _seleccionarFoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _documentoController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Documento de Identidad (No editable)',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nombresController,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _celularController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ] 
            // SI NO HA INICIADO SESIÓN: Se muestra el panel para iniciar sesión
            else ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.account_circle, size: 70, color: Color.fromARGB(255, 0, 30, 255)),
                      const SizedBox(height: 12),
                      const Text(
                        '¡Bienvenido a Spa Vehicular!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inicia sesión para gestionar tus datos personales, consultar tus vehículos y reservar servicios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Iniciar Sesión / Registrarse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Secciones globales con escuchadores reactivos (Modo Oscuro / Tamaño de Letra)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalización Global',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, currentMode, _) {
                        final bool esOscuro = currentMode == ThemeMode.dark;
                        return SwitchListTile(
                          secondary: Icon(
                            esOscuro ? Icons.dark_mode : Icons.light_mode,
                            color: const Color.fromARGB(255, 0, 30, 255),
                          ),
                          title: const Text('Modo Oscuro'),
                          value: esOscuro,
                          onChanged: _cambiarModoOscuro,
                        );
                      },
                    ),
                    const Divider(),
                    ValueListenableBuilder<double>(
                      valueListenable: fontSizeNotifier,
                      builder: (context, fontScale, _) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.format_size, color: Color.fromARGB(255, 0, 30, 255)),
                                    SizedBox(width: 12),
                                    Text('Tamaño de Letra Global'),
                                  ],
                                ),
                                Text(
                                  '${(fontScale * 100).round()}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Slider(
                              value: fontScale,
                              min: 0.8,
                              max: 1.4,
                              divisions: 6,
                              activeColor: const Color.fromARGB(255, 0, 30, 255),
                              onChanged: _cambiarTamanioLetra,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // El botón de "Cerrar Sesión"
            if (_estaAutenticado) ...[
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}