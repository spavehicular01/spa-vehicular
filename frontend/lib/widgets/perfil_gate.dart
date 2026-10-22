import 'package:flutter/material.dart';
import '../main.dart'; // usuarioActualNotifier
import '../screens/completar_perfil_screen.dart';

/// Envuelve la app principal. Si hay un usuario con sesión iniciada al que le
/// falta el Documento de Identidad o el Teléfono, muestra por encima la
/// pantalla para completarlos. Cuando se guardan, la pantalla desaparece sola
/// y no vuelve a salir. El administrador no pasa por aquí.
class PerfilGate extends StatelessWidget {
  final Widget child;

  const PerfilGate({super.key, required this.child});

  static bool _faltanDatos(Map<String, dynamic>? usuario) {
    if (usuario == null) return false;

    final rol = (usuario['rol'] ?? '').toString().toLowerCase();
    if (rol == 'admin') return false;

    final documento =
        (usuario['documento'] ?? usuario['documentoIdentidad'] ?? '')
            .toString()
            .trim();
    final telefono = (usuario['telefono'] ?? usuario['celular'] ?? '')
        .toString()
        .trim();

    return documento.isEmpty || telefono.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: usuarioActualNotifier,
      child: child,
      builder: (context, usuario, hijo) {
        return Stack(
          fit: StackFit.expand,
          children: [
            hijo!,
            if (_faltanDatos(usuario))
              Positioned.fill(
                child: CompletarPerfilScreen(usuario: usuario!),
              ),
          ],
        );
      },
    );
  }
}