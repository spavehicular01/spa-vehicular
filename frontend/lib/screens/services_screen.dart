import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import '../services/wash_service.dart';
import '../widgets/auth_required_dialog.dart';
import 'calendar_screen.dart';
import '../widgets/service_card.dart';

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

  void _irACalendario(String token) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarScreen(token: token),
      ),
    );
  }

  Future<void> _validarSesionYAgendar(ServiceModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (!_tokenEsValido(token)) {
      if (!mounted) return;
      AuthRequiredDialog.show(
        context,
        onLoginExitoso: (Map<String, dynamic> datos) {
          // 'datos' viene del login exitoso; ajusta la key según lo que
          // realmente devuelva tu LoginScreen (ej: datos['token']).
          final nuevoToken = datos['token'] as String?;
          if (nuevoToken != null) {
            _irACalendario(nuevoToken);
          }
        },
      );
      return;
    }

    _irACalendario(token!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios de Lavado'),
        backgroundColor: const Color.fromARGB(255, 0, 26, 255),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<ServiceModel>>(
          future: _futureLavados,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error al cargar servicios:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No hay servicios disponibles.'),
              );
            }

            final lavados = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lavados.length,
              itemBuilder: (context, index) {
                final item = lavados[index];
                return ServiceCard(
                  key: ValueKey(item.id), // ajusta al campo id real de ServiceModel
                  service: item,
                  onTap: () => _validarSesionYAgendar(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}