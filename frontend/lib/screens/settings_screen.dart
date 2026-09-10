import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Notificadores globales
import '../theme/app_theme.dart';
import '../services/user_service.dart';

import '../widgets/settings/profile_avatar.dart';
import '../widgets/settings/profile_form.dart';
import '../widgets/settings/login_prompt_card.dart';
import '../widgets/settings/global_settings_card.dart';

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
      text: widget.usuario?['documento'] ??
          widget.usuario?['cedula'] ??
          widget.usuario?['documentoIdentidad'] ??
          'Sin Documento',
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

  Future<void> _guardarCambios() async {
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
              ProfileAvatar(
                imagenSeleccionada: _imagenSeleccionada,
                avatarUrl: _avatarUrl,
                onTapCambiarFoto: _seleccionarFoto,
              ),
              const SizedBox(height: 24),
              ProfileForm(
                documentoController: _documentoController,
                nombresController: _nombresController,
                apellidosController: _apellidosController,
                celularController: _celularController,
                isLoading: _isLoading,
                onGuardar: _guardarCambios,
              ),
              const SizedBox(height: 24),
            ] else ...[
              LoginPromptCard(
                onIniciarSesion: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              const SizedBox(height: 24),
            ],

            GlobalSettingsCard(
              esModoOscuro: esModoOscuro,
              fontScale: fontSizeNotifier.value,
              onCambiarModoOscuro: _cambiarModoOscuro,
              onCambiarTamanioLetra: _cambiarTamanioLetra,
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