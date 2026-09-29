import 'package:flutter/material.dart';
import 'admin_appointments_screen.dart';
import 'admin_services_screen.dart';
import 'admin_clients_screen.dart';
import 'history_washes_screen.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onCerrarSesion;

  const AdminDashboardScreen({
    super.key,
    required this.userData,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de información del Administrador
          Card(
            color: const Color(0x1A00E5FF), // cian al 10%, igual que el resto de la app
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 28,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['nombres'] ?? 'Administrador SPA',
                          style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData['correo'] ?? 'spavehicular01@gmail.com',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Panel Administrativo', style: AppTextStyles.h2),
          const SizedBox(height: 16),

          // Módulos del Panel: color único (navy) para los 4, como en la
          // referencia AquaGlow, en vez de 4 tonos de azul casi idénticos.
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildCardModulo(
                titulo: 'Gestión de Citas',
                icono: Icons.calendar_month_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminAppointmentsScreen(),
                    ),
                  );
                },
              ),
              _buildCardModulo(
                titulo: 'Servicios y Precios',
                icono: Icons.local_car_wash_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminServicesScreen(),
                    ),
                  );
                },
              ),
              _buildCardModulo(
                titulo: 'Lista de Clientes',
                icono: Icons.people_alt_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminClientsScreen(),
                    ),
                  );
                },
              ),
              _buildCardModulo(
                titulo: 'Reportes e Historial',
                icono: Icons.bar_chart_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryWashesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCerrarSesion,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Cerrar Sesión Administrador',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardModulo({
    required String titulo,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40, color: AppColors.accent),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}