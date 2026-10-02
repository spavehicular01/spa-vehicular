import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Importante para acceder a los Notifier globales
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'forgot_password_screen.dart';

import '../widgets/settings/profile_avatar.dart';
import '../widgets/settings/profile_form.dart';
import '../widgets/settings/login_prompt_card.dart';
import '../widgets/settings/global_settings_card.dart';

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
  late TextEditingController _correoController;

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
      text: widget.usuario?['documento'] ??
          widget.usuario?['cedula'] ??
          widget.usuario?['documentoIdentidad'] ??
          'Sin Documento',
    );
    _correoController = TextEditingController(
      text: (widget.usuario?['correo'] ?? widget.usuario?['email'] ?? '').toString(),
    );
    _avatarUrl = widget.usuario?['avatar'] ?? widget.usuario?['imagenUrl'];
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _celularController.dispose();
    _documentoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _cambiarModoOscuro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modo_oscuro', value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  Future<void> _cambiarTamanioLetra(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', value);
    fontSizeNotifier.value = value;
    setState(() {});
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
      setState(() {
        if (resultado['usuario']['avatar'] != null) {
          _avatarUrl = resultado['usuario']['avatar'];
        }
        _imagenSeleccionada = null;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['message'] ?? 'Perfil actualizado'),
        backgroundColor: resultado['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> _cambiarPassword(String actual, String nueva) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'currentPassword': actual, 'newPassword': nueva}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return null;
      return (data['message'] ?? data['mensaje'])?.toString() ??
          'No se pudo cambiar la contraseña';
    } catch (_) {
      return 'Error de conexión con el servidor';
    }
  }

  void _mostrarDialogoCambiarPassword() {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool guardando = false;
    bool ocultar = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: actualCtrl,
                  obscureText: ocultar,
                  enabled: !guardando,
                  decoration: const InputDecoration(labelText: 'Contraseña actual'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nuevaCtrl,
                  obscureText: ocultar,
                  enabled: !guardando,
                  decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  obscureText: ocultar,
                  enabled: !guardando,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(ocultar ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setModal(() => ocultar = !ocultar),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);

                      if (actualCtrl.text.isEmpty || nuevaCtrl.text.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Completa todos los campos')),
                        );
                        return;
                      }
                      if (nuevaCtrl.text.length < 6) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Mínimo 6 caracteres')),
                        );
                        return;
                      }
                      if (nuevaCtrl.text != confirmCtrl.text) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Las contraseñas no coinciden')),
                        );
                        return;
                      }

                      setModal(() => guardando = true);
                      final error = await _cambiarPassword(actualCtrl.text, nuevaCtrl.text);

                      if (!ctx.mounted) return;
                      if (error == null) {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Contraseña actualizada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setModal(() => guardando = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esModoOscuro = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
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
                correoController: _correoController,
                nombresController: _nombresController,
                apellidosController: _apellidosController,
                celularController: _celularController,
                isLoading: _isLoading,
                onGuardar: _guardarCambios,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: const Color(0x1A00E5FF),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Cambiar contraseña'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _mostrarDialogoCambiarPassword,
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: const Text('¿Has olvidado tu contraseña?'),
                    ),
                  ],
                ),
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
                onTap: () {
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