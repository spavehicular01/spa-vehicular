import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// Ventana de confirmación para eliminar la cuenta (requisito de Google Play).
/// La usan el Perfil del cliente y el Panel del administrador.
/// Devuelve true si la cuenta fue eliminada.
class EliminarCuentaDialog {
  static Future<bool> mostrar(BuildContext context) async {
    final controladorConfirmacion = TextEditingController();
    final controladorPassword = TextEditingController();
    bool pedirPassword = false;
    bool cargando = false;
    String? error;

    final eliminada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> enviar() async {
            setDialogState(() {
              cargando = true;
              error = null;
            });

            final resultado = await AuthService.eliminarCuenta(
              confirmacion: controladorConfirmacion.text.trim(),
              password: controladorPassword.text,
            );

            if (resultado['success'] == true) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
              return;
            }

            setDialogState(() {
              cargando = false;
              if (resultado['requierePassword'] == true) pedirPassword = true;
              error = resultado['message']?.toString();
            });
          }

          return AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Se eliminarán tu cuenta y tus datos personales. '
                    'Esta acción no se puede deshacer.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controladorConfirmacion,
                    enabled: !cargando,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Escribe ELIMINAR para confirmar',
                    ),
                  ),
                  if (pedirPassword) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: controladorPassword,
                      enabled: !cargando,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: cargando ? null : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: cargando ? null : enviar,
                child: cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );

    return eliminada == true;
  }
}