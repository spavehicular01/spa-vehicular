import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Importante para acceder a los Notifier globales
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const SettingsScreen({super.key, this.usuario});

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

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.usuario?['nombres'] ?? widget.usuario?['nombre'] ?? '');
    _apellidosController = TextEditingController(text: widget.usuario?['apellidos'] ?? '');
    _celularController = TextEditingController(text: widget.usuario?['celular'] ?? widget.usuario?['telefono'] ?? '');
    
    // El documento no se edita para evitar duplicados en la BD
    _documentoController = TextEditingController(
      text: widget.usuario?['documento'] ?? widget.usuario?['cedula'] ?? 'Sin Documento',
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

  // Métodos que notifican al instante a toda la app
  Future<void> _cambiarModoOscuro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modo_oscuro', value);
    
    // Cambia el tema global al instante
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  Future<void> _cambiarTamanioLetra(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', value);
    
    // Cambia la escala de texto global al instante
    fontSizeNotifier.value = value;
    setState(() {});
  }

  Future<void> _seleccionarFoto() async {
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
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['message'] ?? 'Perfil actualizado'),
        backgroundColor: resultado['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esModoOscuro = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar con opción de foto
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

            // Documento de Identidad (Bloqueado)
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

            // Personalización Global (Modo Oscuro y Tamaño de Letra)
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
                    SwitchListTile(
                      secondary: Icon(
                        esModoOscuro ? Icons.dark_mode : Icons.light_mode,
                        color: const Color.fromARGB(255, 0, 30, 255),
                      ),
                      title: const Text('Modo Oscuro'),
                      value: esModoOscuro,
                      onChanged: (val) => _cambiarModoOscuro(val),
                    ),
                    const Divider(),
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
                          '${(fontSizeNotifier.value * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: fontSizeNotifier.value,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      activeColor: const Color.fromARGB(255, 0, 30, 255),
                      onChanged: (val) => _cambiarTamanioLetra(val),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 40),

            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}