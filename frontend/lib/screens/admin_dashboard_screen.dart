import 'package:flutter/material.dart';
import 'admin_appointments_screen.dart';
import 'admin_services_screen.dart';
import 'admin_clients_screen.dart';

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de información del Administrador
          Card(
            color: isDark ? const Color(0xFF1E293B) : Colors.teal.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color.fromARGB(255, 0, 8, 255),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 0, 21, 249),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData['correo'] ?? 'spavehicular01@gmail.com',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : const Color.fromARGB(255, 97, 97, 97),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Panel Administrativo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF60A5FA) : const Color.fromARGB(255, 0, 17, 255),
            ),
          ),
          const SizedBox(height: 16),

          // Módulos del Panel
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
                color: const Color.fromARGB(255, 0, 38, 255),
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
                color: const Color.fromARGB(255, 4, 0, 255),
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
                color: const Color.fromARGB(255, 38, 0, 255),
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
                color: const Color.fromARGB(255, 0, 30, 255),
                onTap: () {
                  // Módulo de reportes
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón de Cerrar Sesión
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 42, color: Colors.white),
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
      ),
    );
  }
}