import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/wash_service.dart';
import '../widgets/auth_required_dialog.dart';
import 'calendar_screen.dart';
import '../widgets/service_card.dart';
import '../main.dart'; // usuarioActualNotifier, guardarSesionUsuario
import '../theme/app_theme.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<ServiceModel>> _futureLavados;

  @override
  void initState() {
    super.initState();
    _futureLavados = WashApiService.getLavados();
  }

  Future<void> _recargar() async {
    setState(() {
      _futureLavados = WashApiService.getLavados();
    });
    await _futureLavados;
  }

  bool _tokenEsValido(String? token) {
    return token != null && token.trim().isNotEmpty && token.trim() != 'null';
  }

  void _irACalendario(String token, Map<String, dynamic>? usuario) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarScreen(
          token: token,
          usuario: usuario,
        ),
      ),
    );
  }

  Future<void> _validarSesionYAgendar(ServiceModel item) async {
    final String? token = usuarioActualNotifier.value?['token'] as String?;
    final Map<String, dynamic>? usuario = usuarioActualNotifier.value;

    if (!_tokenEsValido(token)) {
      if (!mounted) return;
      AuthRequiredDialog.show(
        context,
        onLoginExitoso: (Map<String, dynamic> datos) async {
          await guardarSesionUsuario(datos);
          final nuevoToken = datos['token'] as String?;
          if (nuevoToken != null) {
            _irACalendario(nuevoToken, datos);
          }
        },
      );
      return;
    }

    _irACalendario(token!, usuario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Servicios de Lavado'),
        // Ya no hace falta el Color hardcodeado: AppBarTheme lo hereda
        // automáticamente desde AppTheme.light()/dark() en main.dart.
      ),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: _recargar,
        child: FutureBuilder<List<ServiceModel>>(
          future: _futureLavados,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar servicios:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _recargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_car_wash_outlined,
                          color: AppColors.muted, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay servicios disponibles.',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              );
            }

            final lavados = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lavados.length,
              itemBuilder: (context, index) {
                final item = lavados[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ServiceCard(
                    key: ValueKey(item.id),
                    service: item,
                    onTap: () => _validarSesionYAgendar(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}