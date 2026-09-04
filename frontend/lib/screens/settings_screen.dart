import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Notificadores globales
import '../theme/app_theme.dart';
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

      usuarioActualizado['id'] = userId;
      usuarioActualizado['_id'] = userId;

      setState(() {
        if (usuarioActualizado['avatar'] != null) {
          _avatarUrl = usuarioActualizado['avatar'];
        }
        _imagenSeleccionada = null;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(usuarioActualizado));

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

  void _mostrarDialogoCambiarPassword() {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: actualCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña Actual',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nuevaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.azulElectrico,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: enviando
                      ? null
                      : () async {
                          final userId = widget.usuario?['id'] ?? widget.usuario?['_id'];
                          if (userId == null) return;

                          setDialogState(() => enviando = true);

                          final res = await UserService.cambiarPassword(
                            id: userId.toString(),
                            passwordActual: actualCtrl.text.trim(),
                            nuevaPassword: nuevaCtrl.text.trim(),
                          );

                          setDialogState(() => enviando = false);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Procesado'),
                              backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                            ),
                          );
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_estaAutenticado ? 'Ajustes de Perfil' : 'Ajustes y Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_estaAutenticado) ...[
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.azulElectrico,
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
                            color: AppTheme.azulElectrico,
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
                decoration: InputDecoration(
                  labelText: 'Documento de Identidad (No editable)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
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
                  backgroundColor: AppTheme.azulElectrico,
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
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _mostrarDialogoCambiarPassword,
                icon: const Icon(Icons.lock_reset, color: AppTheme.azulElectrico),
                label: const Text('Cambiar Contraseña', style: TextStyle(color: AppTheme.azulElectrico)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.azulElectrico),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Card(
                elevation: 3,
                color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.account_circle, size: 70, color: AppTheme.azulElectrico),
                      const SizedBox(height: 12),
                      const Text(
                        '¡Bienvenido a Spa Vehicular!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para gestionar tus datos personales, consultar tus vehículos y reservar servicios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Iniciar Sesión / Registrarse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.azulElectrico,
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

            Card(
              elevation: 2,
              color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
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
                            color: AppTheme.azulElectrico,
                          ),
                          title: const Text('Modo Oscuro'),
                          value: esOscuro,
                          activeColor: AppTheme.azulElectrico,
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
                                    Icon(Icons.format_size, color: AppTheme.azulElectrico),
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
                              activeColor: AppTheme.azulElectrico,
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
                  await prefs.remove('user_data');
                  await prefs.remove('token');
                  
                  if (!mounted) return;

                  widget.onUsuarioActualizado?.call({});
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