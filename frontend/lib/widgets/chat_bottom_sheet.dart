import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/chat_service.dart';

/// Paleta azul translúcida del chat (efecto "cristal").
class _ChatColors {
  static const glassTop = Color(0xB3103A68); // azul, ~70% opaco
  static const glassBottom = Color(0xD90A1A33); // azul marino, ~85% opaco
  static const accent = Color(0xFF22D3EE); // cian
  static const onAccent = Color(0xFF0A1A33); // texto/ícono sobre el cian
  static const border = Color(0x4D22D3EE);
  static const botBubble = Color(0x1FFFFFFF); // blanco 12%
  static const botBubbleBorder = Color(0x1AFFFFFF);
  static const chipFill = Color(0x1A22D3EE);
  static const chipBorder = Color(0x8022D3EE);
  static const inputFill = Color(0x1FFFFFFF);
  static const inputBorder = Color(0x33FFFFFF);
  static const text = Colors.white;
  static const textMuted = Color(0x99FFFFFF);
}

class ChatBottomSheet extends StatefulWidget {
  const ChatBottomSheet({super.key});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _mensajes = [
    {
      'role': 'bot',
      'text': '¡Hola! 🚗✨ Soy tu asesor virtual del Spa Vehicular. Pregúntame sobre nuestros servicios, precios o disponibilidad de agenda.',
    }
  ];
  bool _cargando = false;

  // Preguntas rápidas que se muestran al abrir el chat.
  static const List<String> _sugerencias = [
    'Servicios y precios',
    'Horarios de atención',
    'Cómo agendar una cita',
    'Formas de pago',
    'Lavado a domicilio',
    'Reprogramar o cancelar',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Envía lo escrito en el campo, o [sugerido] si se toca una pregunta rápida.
  void _enviarMensaje([String? sugerido]) async {
    final texto = (sugerido ?? _controller.text).trim();
    if (texto.isEmpty || _cargando) return;

    // Mensajes previos (sin el saludo inicial) para que el asesor tenga contexto.
    final historial = _mensajes.skip(1).toList();

    _controller.clear();
    setState(() {
      _mensajes.add({'role': 'user', 'text': texto});
      _cargando = true;
    });

    _scrollHaciaAbajo();

    final respuesta = await ChatService.enviarMensaje(texto, historial: historial);

    if (mounted) {
      setState(() {
        _mensajes.add({'role': 'bot', 'text': respuesta});
        _cargando = false;
      });
      _scrollHaciaAbajo();
    }
  }

  void _scrollHaciaAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildSugerencias() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _sugerencias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          // Chip propio (no ActionChip) para que el tema global de la app
          // no le ponga fondo blanco.
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _enviarMensaje(_sugerencias[i]),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _ChatColors.chipFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ChatColors.chipBorder),
                ),
                child: Text(
                  _sugerencias[i],
                  style: const TextStyle(
                    color: _ChatColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final mostrarSugerencias = _mensajes.length <= 1 && !_cargando;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_ChatColors.glassTop, _ChatColors.glassBottom],
              ),
              border: Border(top: BorderSide(color: _ChatColors.border)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: _ChatColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: _ChatColors.onAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asesor Virtual',
                            style: TextStyle(
                              color: _ChatColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'En línea • Respuestas al instante',
                            style: TextStyle(
                              color: _ChatColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final item = _mensajes[index];
                      final esUsuario = item['role'] == 'user';

                      return Align(
                        alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: esUsuario ? _ChatColors.accent : _ChatColors.botBubble,
                            border: esUsuario
                                ? null
                                : Border.all(color: _ChatColors.botBubbleBorder),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(esUsuario ? 16 : 4),
                              bottomRight: Radius.circular(esUsuario ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            item['text']!,
                            style: TextStyle(
                              color: esUsuario ? _ChatColors.onAccent : _ChatColors.text,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _ChatColors.accent,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'El asesor está respondiendo...',
                          style: TextStyle(color: _ChatColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (mostrarSugerencias) ...[
                  _buildSugerencias(),
                  const SizedBox(height: 4),
                ],
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _ChatColors.inputFill,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _ChatColors.inputBorder),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: _ChatColors.text),
                            cursorColor: _ChatColors.accent,
                            textInputAction: TextInputAction.send,
                            // Se anulan el fondo claro y los bordes que el tema global
                            // (inputDecorationTheme) le pone a todos los campos de texto.
                            decoration: const InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Pregunta por precios, servicios o citas...',
                              hintStyle: TextStyle(color: _ChatColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _enviarMensaje(),
                        style: IconButton.styleFrom(
                          backgroundColor: _ChatColors.accent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(
                          Icons.send_rounded,
                          color: _ChatColors.onAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
