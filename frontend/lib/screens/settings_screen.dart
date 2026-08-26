import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color.fromARGB(255, 0, 30, 255),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Configuraciones de la aplicación (En construcción)'),
      ),
    );
  }
}