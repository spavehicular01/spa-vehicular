import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show usuarioActualNotifier, cerrarSesionUsuario;
import '../services/perfil_service.dart';
import '../theme/app_theme.dart';

/// Pantalla que pide Apellidos, Documento de Identidad y Teléfono cuando faltan
/// (por ejemplo, tras entrar con Google). Se muestra una sola vez:
/// al guardar, los datos quedan en la cuenta y no se vuelven a pedir.
class CompletarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const CompletarPerfilScreen({super.key, required this.usuario});

  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apellidosController;
  late final TextEditingController _documentoController;
  late final TextEditingController _telefonoController;
  late final bool _documentoYaExiste;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final ape = (widget.usuario['apellidos'] ?? widget.usuario['Apellido'] ?? '')
        .toString()
        .trim();
    final doc = (widget.usuario['documento'] ??
            widget.usuario['documentoIdentidad'] ??
            '')
        .toString()
        .trim();
    final tel =
        (widget.usuario['telefono'] ?? widget.usuario['celular'] ?? '')
            .toString()
            .trim();
    _documentoYaExiste = doc.isNotEmpty;
    _apellidosController = TextEditingController(text: ape);
    _documentoController = TextEditingController(text: doc);
    _telefonoController = TextEditingController(text: tel);
  }

  @override
  void dispose() {
    _apellidosController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final userId =
        (widget.usuario['id'] ?? widget.usuario['_id'] ?? '').toString();
    final apellidos = _apellidosController.text.trim();
    final documento = _documentoController.text.trim();
    final telefono = _telefonoController.text.trim();

    final resultado = await PerfilService.completarPerfil(
      userId: userId,
      apellidos: apellidos,
      documento: documento,
      telefono: telefono,
    );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message']?.toString() ?? 'No se pudo guardar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Se actualiza la sesión local; el PerfilGate detecta el cambio y deja pasar a la app.
    final nuevo = Map<String, dynamic>.from(widget.usuario)
      ..['apellidos'] = apellidos
      ..['documento'] = documento
      ..['telefono'] = telefono;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(nuevo));
    usuarioActualNotifier.value = nuevo;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nombre = (widget.usuario['nombres'] ?? '').toString().trim();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Completa tu perfil'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.badge, size: 42, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombre.isEmpty ? '¡Bienvenido!' : '¡Hola, $nombre!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para continuar necesitamos tus apellidos, tu documento y tu teléfono. '
                    'Solo te los pediremos esta vez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _apellidosController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Ingresa tus apellidos' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _documentoController,
                    readOnly: _documentoYaExiste,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Documento de Identidad',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Ingresa tu documento';
                      if (t.length < 5) return 'Documento inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Número de Teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.length < 7) return 'Ingresa un teléfono válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.brand,
                      foregroundColor: context.onBrand,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _guardando
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: context.onBrand,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Guardar y continuar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _guardando ? null : cerrarSesionUsuario,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}