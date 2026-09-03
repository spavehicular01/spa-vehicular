import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  // Azul puro eléctrico exacto (#0033FF)
  static const Color azulElectrico = Color(0xFF0033FF);

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
      body: Stack(
        children: [
          // Animación suave de agua en el fondo
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.04 : 0.06,
              child: Lottie.asset(
                'assets/animations/water_waves.json',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          FutureBuilder<List<WashService>>(
            future: _futureLavados,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: azulElectrico));
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar servicios:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No hay servicios disponibles.',
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                );
              }

              final lavados = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lavados.length,
                itemBuilder: (context, index) {
                  final item = lavados[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => _validarSesionYAgendar(context, item),
                        contentPadding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: azulElectrico.withOpacity(0.12),
                                        child: const Icon(Icons.directions_car, size: 36, color: azulElectrico),
                                      ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: azulElectrico.withOpacity(0.12),
                                  child: const Icon(Icons.directions_car, size: 36, color: azulElectrico),
                                ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          ),
                          child: Text(item.description),
                        ),
                        trailing: Text(
                          '\$${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: azulElectrico,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}