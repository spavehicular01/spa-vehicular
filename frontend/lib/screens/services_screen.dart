import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wash_service.dart';
import '../services/wash_service.dart';
import '../widgets/auth_required_dialog.dart';
import 'calendar_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<WashService>> _futureLavados;

  @override
  void initState() {
    super.initState();
    _futureLavados = WashApiService.getLavados();
  }

  Future<void> _validarSesionYAgendar(BuildContext context, WashService item) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null || token.trim().isEmpty || token == 'null') {
      if (!context.mounted) return;
      AuthRequiredDialog.show(context);
      return;
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarScreen(token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios de Lavado'),
        backgroundColor: const Color.fromARGB(255, 0, 26, 255),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<WashService>>(
        future: _futureLavados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar servicios:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
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
                service: item,
                onTap: () => _validarSesionYAgendar(context, item),
              );
            },
          );
        },
      ),
    );
  }
}