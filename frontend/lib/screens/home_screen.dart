import 'package:flutter/material.dart';
import '../widgets/auth_required_dialog.dart';
import 'services_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? usuarioAutenticado;
  final void Function(Map<String, dynamic> datos)? onLoginExitoso;

  const HomeScreen({
    super.key,
    this.usuarioAutenticado,
    this.onLoginExitoso,
  });

  void _validarYIrAServicios(BuildContext context) {
    if (usuarioAutenticado == null) {
      AuthRequiredDialog.show(
        context,
        onLoginExitoso: (datos) {
          onLoginExitoso?.call(datos);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServicesScreen()),
          );
        },
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ServicesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ojo: sin Scaffold/AppBar propios a propósito — esta pantalla siempre
    // vive dentro de MainNavigationScreen, que ya provee el Scaffold y el
    // AppBar. Tener dos AppBar aquí causaba la barra superior duplicada.
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // Banner de Bienvenida
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF10294A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_car_wash,
                        size: 34, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '¡Bienvenido a Spa Vehicular!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'El mejor cuidado y limpieza para tu vehículo',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Servicios Rápidos', style: AppTextStyles.h2),
            ),

            // Tarjeta de Opción a Servicios (estilo AquaGlow)
            Card(
              child: InkWell(
                onTap: () => _validarYIrAServicios(context),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0x1A00E5FF), // accent al 10%
                        child: Icon(Icons.cleaning_services,
                            color: AppColors.secondary, size: 24),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Servicios de Lavado',
                                style: AppTextStyles.bodyStrong),
                            SizedBox(height: 4),
                            Text('Ver catálogo de servicios y precios',
                                style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: AppColors.secondary, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}