import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Header del Inicio: degradado, burbujas decorativas y saludo.
class HomeHeader extends StatelessWidget {
  final Map<String, dynamic>? usuario;
  final VoidCallback? onIniciarSesion;

  const HomeHeader({super.key, this.usuario, this.onIniciarSesion});

  @override
  Widget build(BuildContext context) {
    final logueado = usuario != null;
    final nombreCompleto =
        (usuario?['nombres'] ?? usuario?['nombre'] ?? '').toString().trim();
    final nombre = nombreCompleto.isEmpty ? '' : nombreCompleto.split(' ').first;
    final inicial = nombre.isEmpty ? 'U' : nombre[0].toUpperCase();

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF12406B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -34, child: _burbuja(130, 0.06)),
          Positioned(right: 56, bottom: -22, child: _burbuja(64, 0.12, cian: true)),
          Positioned(left: -24, bottom: -34, child: _burbuja(90, 0.05)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent,
                    child: logueado
                        ? Text(
                            inicial,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : const Icon(Icons.local_car_wash,
                            color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logueado
                              ? (nombre.isEmpty ? 'Hola' : 'Hola, $nombre')
                              : '¡Bienvenido a Spa Vehicular!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          logueado
                              ? 'Agenda tu próxima lavada en pocos pasos.'
                              : 'El mejor cuidado y limpieza para tu vehículo',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!logueado) ...[
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onIniciarSesion,
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _burbuja(double d, double alpha, {bool cian = false}) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (cian ? AppColors.accent : Colors.white).withValues(alpha: alpha),
        ),
      );
}