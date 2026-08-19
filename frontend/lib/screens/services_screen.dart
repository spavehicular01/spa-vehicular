import 'package:flutter/material.dart';
import '../models/wash_service.dart';
import '../services/wash_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios de Lavado'),
        backgroundColor: Colors.teal,
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
                'Error al conectar con la API:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay servicios de lavado disponibles.'),
            );
          }

          final lavados = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lavados.length,
            itemBuilder: (context, index) {
              final item = lavados[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.directions_car, size: 40, color: Colors.teal),
                          )
                        : const Icon(Icons.directions_car, size: 40, color: Colors.teal),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(item.description),
                  ),
                  trailing: Text(
                    '\$${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}