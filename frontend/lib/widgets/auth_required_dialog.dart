import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../theme/app_theme.dart';

class AuthRequiredDialog extends StatelessWidget {
  final void Function(Map<String, dynamic> datos) onLoginExitoso;

  const AuthRequiredDialog({super.key, required this.onLoginExitoso});

  /// Muestra el diálogo desde cualquier pantalla. Requiere el callback real que
  /// actualiza el estado de sesión, para que el login/registro realmente "cuente".
  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> datos) onLoginExitoso,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AuthRequiredDialog(
        onLoginExitoso: onLoginExitoso,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final Color textoPrincipal = isDark ? AppColors.darkText : AppColors.primary;
    final Color textoSuave = isDark ? AppColors.darkMuted : AppColors.muted;

    final RoundedRectangleBorder forma =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? const BorderSide(color: AppColors.darkBorder)
            : BorderSide.none,
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            'Atención',
            style: TextStyle(fontWeight: FontWeight.bold, color: textoPrincipal),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Para agendar un servicio en SPA Vehicular necesitas iniciar sesión o registrarte.',
            style: TextStyle(color: textoPrincipal),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
            onPressed: () {
              // Se toma el Navigator antes de cerrar el diálogo.
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(onLoginExitoso: onLoginExitoso),
                ),
              );
            },
            child: const Text('Iniciar Sesión'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.brandText,
              side: BorderSide(color: context.brandText, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: forma,
            ),
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(onLoginExitoso: onLoginExitoso),
                ),
              );
            },
            child: const Text('Registrarse'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: textoSuave),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}