import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _modoOscuro = false;
  double _fontSizeScale = 1.0;
  
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
    _cargarPreferencias();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _celularController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _modoOscuro = prefs.getBool('modo_oscuro') ?? false;
      _fontSizeScale = prefs.getDouble('font_scale') ?? 1.0;
    });
  }

  Future<void> _guardarPreferencia(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
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
    final Color backgroundColor = _modoOscuro ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final Color cardColor = _modoOscuro ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = _modoOscuro ? Colors.white : Colors.black87;

    return Theme(
      data: (_modoOscuro ? ThemeData.dark() : ThemeData.light()).copyWith(
        scaffoldBackgroundColor: backgroundColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Ajustes de Perfil',
            style: TextStyle(fontSize: 20 * _fontSizeScale),
          ),
          backgroundColor: const Color.fromARGB(255, 0, 30, 255),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar con botón de cámara
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

              // Campo Documento Bloqueado (No editable)
              TextField(
                controller: _documentoController,
                enabled: false,
                style: TextStyle(fontSize: 15 * _fontSizeScale),
                decoration: InputDecoration(
                  labelText: 'Documento de Identidad (No editable)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: _modoOscuro ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nombresController,
                style: TextStyle(fontSize: 15 * _fontSizeScale),
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _apellidosController,
                style: TextStyle(fontSize: 15 * _fontSizeScale),
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
                style: TextStyle(fontSize: 15 * _fontSizeScale),
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
                    : Text(
                        'Guardar Cambios',
                        style: TextStyle(fontSize: 16 * _fontSizeScale, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),

              // Sección Apariencia (Modo Oscuro y Tamaño de Letra)
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalización',
                        style: TextStyle(
                          fontSize: 15 * _fontSizeScale,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          _modoOscuro ? Icons.dark_mode : Icons.light_mode,
                          color: const Color.fromARGB(255, 0, 30, 255),
                        ),
                        title: Text(
                          'Modo Oscuro',
                          style: TextStyle(fontSize: 14 * _fontSizeScale, color: textColor),
                        ),
                        value: _modoOscuro,
                        onChanged: (val) {
                          setState(() => _modoOscuro = val);
                          _guardarPreferencia('modo_oscuro', val);
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_size, color: Color.fromARGB(255, 0, 30, 255)),
                              const SizedBox(width: 12),
                              Text(
                                'Tamaño de Letra',
                                style: TextStyle(fontSize: 14 * _fontSizeScale, color: textColor),
                              ),
                            ],
                          ),
                          Text(
                            '${(_fontSizeScale * 100).round()}%',
                            style: TextStyle(fontSize: 14 * _fontSizeScale, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: _fontSizeScale,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        activeColor: const Color.fromARGB(255, 0, 30, 255),
                        onChanged: (val) {
                          setState(() => _fontSizeScale = val);
                          _guardarPreferencia('font_scale', val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 40),

              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15 * _fontSizeScale,
                  ),
                ),
                onTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}