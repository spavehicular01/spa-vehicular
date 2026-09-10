import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/wash_service.dart';
import '../widgets/auth_required_dialog.dart';
import 'calendar_screen.dart';
import '../widgets/service_card.dart';
import '../main.dart'; // usuarioActualNotifier, guardarSesionUsuario

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

  // 🟢 FIX: ahora también recibe y pasa el usuario, no solo el token.
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
            _irACalendario(nuevoToken, datos); // 🟢 ahora también pasa 'datos' como usuario
          }
        },
      );
      return;
    }

    _irACalendario(token!, usuario); // 🟢 ahora también pasa 'usuario'
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Servicios de Lavado', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulElectrico,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
                  key: ValueKey(item.id),
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