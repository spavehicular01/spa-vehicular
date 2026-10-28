import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show usuarioActualNotifier, cerrarSesionUsuario;
import '../screens/completar_perfil_screen.dart';
import '../services/perfil_service.dart';

enum _Estado { consultando, falta, error }

/// Envuelve la app principal. Si hay un usuario (no admin) al que le falta
/// Documento de Identidad o Teléfono, primero confirma con el servidor y,
/// si de verdad faltan, muestra CompletarPerfilScreen. Funciona igual para
/// cuentas nuevas de Google, cuentas existentes y al reabrir la app.
class PerfilGate extends StatefulWidget {
  final Widget child;

  const PerfilGate({super.key, required this.child});

  @override
  State<PerfilGate> createState() => _PerfilGateState();
}

class _PerfilGateState extends State<PerfilGate> {
  final Map<String, _Estado> _estados = {};

  String _id(Map<String, dynamic> u) =>
      (u['id'] ?? u['_id'] ?? '').toString();

  bool _esAdmin(Map<String, dynamic> u) =>
      (u['rol'] ?? '').toString().toLowerCase() == 'admin';

  bool _faltanDatos(Map<String, dynamic> u) {
    final doc =
        (u['documento'] ?? u['documentoIdentidad'] ?? '').toString().trim();
    final tel = (u['telefono'] ?? u['celular'] ?? '').toString().trim();
    return doc.isEmpty || tel.isEmpty;
  }

  Future<void> _consultar(Map<String, dynamic> u) async {
    final id = _id(u);
    final servidor = await PerfilService.obtenerMiPerfil();
    if (!mounted) return;

    if (servidor == null) {
      setState(() => _estados[id] = _Estado.error);
      return;
    }

    final doc = (servidor['documentoIdentidad'] ?? servidor['documento'] ?? '')
        .toString()
        .trim();
    final tel =
        (servidor['celular'] ?? servidor['telefono'] ?? '').toString().trim();

    if (doc.isNotEmpty && tel.isNotEmpty) {
      // El servidor ya los tenía: se actualiza la sesión local y se deja pasar.
      final nuevo = Map<String, dynamic>.from(u)
        ..['documento'] = doc
        ..['telefono'] = tel;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario', jsonEncode(nuevo));
      usuarioActualNotifier.value = nuevo;
    } else {
      // Faltan de verdad: se muestra el formulario con lo que ya exista.
      final conservado = Map<String, dynamic>.from(u)
        ..['documento'] = doc
        ..['telefono'] = tel;
      usuarioActualNotifier.value = conservado;
      setState(() => _estados[id] = _Estado.falta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: usuarioActualNotifier,
      builder: (context, usuario, _) {
        // Sin sesión: se olvida lo consultado, para que al volver a entrar
        // (aunque sea la misma cuenta) se verifique el perfil de nuevo.
        if (usuario == null) {
          _estados.clear();
          return widget.child;
        }

        if (_esAdmin(usuario) || !_faltanDatos(usuario)) {
          return widget.child;
        }

        final id = _id(usuario);
        final estado = _estados[id];

        if (estado == null) {
          _estados[id] = _Estado.consultando;
          WidgetsBinding.instance.addPostFrameCallback((_) => _consultar(usuario));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        switch (estado) {
          case _Estado.consultando:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case _Estado.falta:
            return CompletarPerfilScreen(usuario: usuario);
          case _Estado.error:
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'No pudimos verificar tu perfil. Revisa tu conexión e intenta de nuevo.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _estados.remove(id)),
                          child: const Text('Reintentar'),
                        ),
                        TextButton(
                          onPressed: cerrarSesionUsuario,
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}