import 'package:flutter/material.dart';
import '../widgets/chat_bottom_sheet.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Función para abrir el modal del chat
  void _abrirChatAsesor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
      ),
      body: const Center(
        child: Text('Contenido principal del menú'),
      ),
      // Botón flotante para desplegar el Chat del Asesor Virtual
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_btn_asesor_chat',
        backgroundColor: const Color(0xFFC88D51),
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Consultar al Asesor Virtual',
        onPressed: _abrirChatAsesor,
        child: const Icon(
          Icons.directions_car_rounded,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }
}