import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // guardarSesionUsuario, cerrarSesionUsuario
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/session_utils.dart';

/// Pantalla que se muestra una sola vez tras iniciar sesión (por ejemplo con
/// Google) cuando a la cuenta le faltan el Documento de Identidad o el
/// Número de Teléfono. Al guardar, los datos quedan en el servidor y en la
/// sesión local, así que no se vuelven a pedir.
class CompletarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const CompletarPerfilScreen({super.key, required this.usuario});

  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _documentoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final bool _tieneDocumento;

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final doc = (widget.usuario['documento'] ??
            widget.usuario['documentoIdentidad'] ??
            '')
        .toString()
        .trim();
    final tel =
        (widget.usuario['telefono'] ?? widget.usuario['celular'] ?? '')
            .toString()
            .trim();

    _tieneDocumento = doc.isNotEmpty;
    _documentoCtrl = TextEditingController(text: doc);
    _telefonoCtrl = TextEditingController(text: tel);
  }

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    final id = (widget.usuario['id'] ?? widget.usuario['_id'])?.toString() ??
        await obtenerUserIdSesion() ??
        '';

    if (id.isEmpty) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo identificar tu sesión. Inicia sesión de nuevo.';
      });
      return;
    }

    final documento = _documentoCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    final resultado = await UserService.actualizarPerfil(
      id: id,
      celular: telefono,
      // Si la cuenta ya tenía documento no se vuelve a enviar
      documentoIdentidad: _tieneDocumento ? '' : documento,
    );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() {
        _guardando = false;
        _error = resultado['message']?.toString() ?? 'No se pudo guardar.';
      });
      return;
    }

    // Se actualiza la sesión (memoria + disco). Al cambiar el notificador,
    // el PerfilGate quita esta pantalla por sí solo.
    final devuelto = resultado['usuario'] is Map
        ? Map<String, dynamic>.from(resultado['usuario'] as Map)
        : <String, dynamic>{};

    final actualizado = Map<String, dynamic>.from(widget.usuario);
    actualizado['documento'] =
        (devuelto['documentoIdentidad'] ?? devuelto['documento'] ?? documento)
            .toString();
    actualizado['telefono'] =
        (devuelto['celular'] ?? devuelto['telefono'] ?? telefono).toString();

    await guardarSesionUsuario(actualizado);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nombre = (widget.usuario['nombres'] ?? '').toString().trim();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.badge_outlined,
                          size: 42, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombre.isEmpty ? '¡Un último paso!' : '¡Hola, $nombre!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para agendar tus citas necesitamos tu documento de '
                    'identidad y tu número de teléfono. Solo te los pediremos '
                    'esta vez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _documentoCtrl,
                    enabled: !_tieneDocumento && !_guardando,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Documento de Identidad',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      helperText: _tieneDocumento
                          ? null
                          : 'No se podrá cambiar después',
                    ),
                    validator: (valor) {
                      if (_tieneDocumento) return null;
                      final v = (valor ?? '').trim();
                      if (v.isEmpty) return 'Ingresa tu documento de identidad';
                      if (v.length < 6) {
                        return 'El documento debe tener al menos 6 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoCtrl,
                    enabled: !_guardando,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Número de Teléfono',
                      prefixIcon: Icon(Icons.phone_android),
                      hintText: '3201234567',
                    ),
                    validator: (valor) {
                      final v = (valor ?? '').trim();
                      if (v.isEmpty) return 'Ingresa tu número de teléfono';
                      if (!RegExp(r'^3\d{9}$').hasMatch(v)) {
                        return 'Ingresa un celular válido de 10 dígitos';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.brand,
                      foregroundColor: context.onBrand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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