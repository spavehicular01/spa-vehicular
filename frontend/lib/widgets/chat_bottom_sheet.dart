import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/chat_agenda_service.dart';
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

/// Chat con dos modos con el mismo diseño:
/// - clientes (por defecto): asesor virtual sobre servicios, precios y agenda.
///   Con sesión iniciada también puede AGENDAR citas (por texto o por voz).
/// - administrador ([modoAdmin] = true): asistente de consultas del negocio.
class ChatBottomSheet extends StatefulWidget {
  final bool modoAdmin;

  const ChatBottomSheet({super.key, this.modoAdmin = false});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<Map<String, String>> _mensajes;
  bool _cargando = false;

  // ── Voz ──
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttInicializado = false;
  bool _sttListo = false;
  bool _escuchando = false;
  String _localeVoz = 'es_CO';

  // ── Cita lista para confirmar (la propone el asesor) ──
  Map<String, dynamic>? _accionPendiente;
  bool _confirmando = false;

  bool get _admin => widget.modoAdmin;

  // Preguntas rápidas que se muestran al abrir el chat.
  static const List<String> _sugerenciasCliente = [
    'Quiero agendar una cita',
    'Servicios y precios',
    'Horarios de atención',
    'Formas de pago',
    'Lavado a domicilio',
    'Reprogramar o cancelar',
  ];

  static const List<String> _sugerenciasAdmin = [
    'Citas de hoy',
    'Vehículos en el spa',
    'Citas pendientes',
    'Próximas citas',
    'Lavadas por cobrar',
    'Cobrado hoy',
    'Cobrado esta semana',
    'Servicios y precios',
  ];

  List<String> get _sugerencias => _admin ? _sugerenciasAdmin : _sugerenciasCliente;

  // Palabras con las que se acepta una confirmación hablada o escrita.
  // Solo cuenta si TODO lo dicho son palabras de esta lista (hasta 5 palabras):
  // "sí, pero cámbiala a las 4" NO confirma.
  static const Set<String> _palabrasPermitidas = {
    'si', 'claro', 'dale', 'listo', 'ok', 'okay', 'vale', 'perfecto',
    'correcto', 'adelante', 'confirmo', 'confirma', 'confirmar',
    'confirmala', 'confirmalo', 'agendala', 'agendalo', 'agenda', 'hazlo',
    'de', 'acuerdo', 'por', 'favor', 'esta', 'bien', 'gracias', 'asi', 'es',
    'muy',
  };
  static const Set<String> _palabrasClave = {
    'si', 'claro', 'dale', 'listo', 'ok', 'okay', 'vale', 'perfecto',
    'correcto', 'adelante', 'confirmo', 'confirma', 'confirmar',
    'confirmala', 'confirmalo', 'agendala', 'agendalo', 'agenda', 'hazlo',
    'acuerdo', 'bien',
  };

  @override
  void initState() {
    super.initState();
    _mensajes = [
      {
        'role': 'bot',
        'text': _admin
            ? '¡Hola! 📋 Soy tu asistente del negocio. Pregúntame por las citas de hoy, lo que falta por cobrar, los pagos de la semana o los servicios y precios. También puedes hablarme con el micrófono 🎤.'
            : '¡Hola! 🚗✨ Soy tu asesor virtual del Spa Vehicular. Pregúntame sobre servicios y precios, o dime "quiero agendar una cita" y la hacemos juntos, escribiendo o con el micrófono 🎤.',
      }
    ];
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────── Voz ───────────────────────────

  /// Prepara el reconocimiento de voz la primera vez que se toca el micrófono
  /// (es cuando el teléfono pide el permiso).
  Future<void> _prepararVoz() async {
    _sttInicializado = true;
    try {
      _sttListo = await _stt.initialize(
        onStatus: (estado) {
          if ((estado == 'done' || estado == 'notListening') && mounted) {
            setState(() => _escuchando = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _escuchando = false);
        },
      );

      if (_sttListo) {
        final locales = await _stt.locales();
        final colombia = locales.where(
          (l) => l.localeId.replaceAll('-', '_').toLowerCase() == 'es_co',
        );
        final espanol = locales.where((l) => l.localeId.toLowerCase().startsWith('es'));
        if (colombia.isNotEmpty) {
          _localeVoz = colombia.first.localeId;
        } else if (espanol.isNotEmpty) {
          _localeVoz = espanol.first.localeId;
        }
      }
    } catch (_) {
      _sttListo = false;
    }
  }

  Future<void> _alternarMicrofono() async {
    if (_cargando || _confirmando) return;

    await _tts.stop();

    if (_escuchando) {
      await _stt.stop();
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    if (!_sttInicializado) await _prepararVoz();

    if (!_sttListo) {
      if (!mounted) return;
      setState(() {
        _mensajes.add({
          'role': 'bot',
          'text':
              'No pude activar el micrófono 🎤. Revisa que la app tenga permiso de micrófono en los ajustes del teléfono, y que el reconocimiento de voz de Google esté disponible.',
        });
      });
      _scrollHaciaAbajo();
      return;
    }

    _controller.clear();
    setState(() => _escuchando = true);

    await _stt.listen(
      localeId: _localeVoz,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (resultado) {
        if (!mounted) return;
        _controller.text = resultado.recognizedWords;
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);

        if (resultado.finalResult) {
          setState(() => _escuchando = false);
          if (resultado.recognizedWords.trim().isNotEmpty) {
            _enviarMensaje(porVoz: true);
          }
        }
      },
    );
  }

  /// Quita emojis y símbolos, y dice los precios como "35000 pesos",
  /// para que la voz suene natural.
  String _limpiarParaVoz(String texto) {
    var s = texto.replaceAllMapped(
      RegExp(r'\$\s?([\d.]+)'),
      (m) => '${m[1]!.replaceAll('.', '')} pesos',
    );
    s = s.replaceAll('•', ',').replaceAll('\n', '. ');
    s = s.replaceAll(RegExp(r'[^\p{L}\p{N}\s.,;:¿?¡!/()-]', unicode: true), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _hablar(String texto) async {
    final limpio = _limpiarParaVoz(texto);
    if (limpio.isEmpty) return;
    try {
      final hayColombia = (await _tts.isLanguageAvailable('es-CO')) == true;
      await _tts.setLanguage(hayColombia ? 'es-CO' : 'es-ES');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(limpio);
    } catch (_) {
      // Si la voz del teléfono falla, el texto igual queda en pantalla.
    }
  }

  // ─────────────────── Confirmación de la cita ───────────────────

  String _normalizar(String texto) {
    const conTilde = 'áàäâéèëêíìïîóòöôúùüûñ';
    const sinTilde = 'aaaaeeeeiiiioooouuuun';
    var s = texto.toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      s = s.replaceAll(conTilde[i], sinTilde[i]);
    }
    return s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _esAfirmativo(String texto) {
    final limpio = _normalizar(texto);
    if (limpio.isEmpty) return false;
    final palabras = limpio.split(' ');
    if (palabras.length > 5) return false;
    return palabras.every(_palabrasPermitidas.contains) &&
        palabras.any(_palabrasClave.contains);
  }

  Future<void> _confirmarCita({bool porVoz = false}) async {
    final accion = _accionPendiente;
    if (accion == null || _confirmando) return;

    await _tts.stop();
    setState(() => _confirmando = true);
    _scrollHaciaAbajo();

    final datos = Map<String, dynamic>.from(accion['datos'] as Map);
    final r = await ChatAgendaService.confirmarCita(datos);

    if (!mounted) return;

    final mensaje = r['mensaje'].toString();
    setState(() {
      _confirmando = false;
      // Si hubo respuesta del servidor (éxito o error de negocio) la propuesta
      // se descarta. Si solo falló la conexión, se conserva para reintentar.
      if (r['red'] != true) _accionPendiente = null;
      _mensajes.add({'role': 'bot', 'text': mensaje});
    });
    _scrollHaciaAbajo();

    if (porVoz) _hablar(mensaje);
  }

  void _cancelarPropuesta() {
    setState(() {
      _accionPendiente = null;
      _mensajes.add({
        'role': 'bot',
        'text':
            'Sin problema, no agendé nada. ¿Qué quieres cambiar: el servicio, el vehículo, la fecha o la hora?',
      });
    });
    _scrollHaciaAbajo();
  }

  // ───────────────────────── Envío de mensajes ─────────────────────────

  /// Envía lo escrito en el campo, o [sugerido] si se toca una pregunta rápida.
  /// [porVoz] = true cuando el texto viene del micrófono: el asesor responde corto
  /// y su respuesta se lee en voz alta.
  Future<void> _enviarMensaje({String? sugerido, bool porVoz = false}) async {
    final texto = (sugerido ?? _controller.text).trim();
    if (texto.isEmpty || _cargando || _confirmando) return;

    _tts.stop();
    if (_escuchando) {
      _stt.stop();
      _escuchando = false;
    }

    // Si hay una cita esperando confirmación:
    // un "sí" claro la confirma; cualquier otra cosa la descarta y se sigue conversando.
    if (_accionPendiente != null) {
      if (_esAfirmativo(texto)) {
        _controller.clear();
        setState(() => _mensajes.add({'role': 'user', 'text': texto}));
        _scrollHaciaAbajo();
        await _confirmarCita(porVoz: porVoz);
        return;
      }
      _accionPendiente = null;
    }

    // Mensajes previos (sin el saludo inicial) para que el asesor tenga contexto.
    final historial = _mensajes.skip(1).toList();

    _controller.clear();
    setState(() {
      _mensajes.add({'role': 'user', 'text': texto});
      _cargando = true;
    });

    _scrollHaciaAbajo();

    String respuesta;
    String? respuestaVoz;
    Map<String, dynamic>? accion;

    if (_admin) {
      respuesta = await ChatService.enviarMensajeAdmin(texto, historial: historial);
    } else {
      final r = await ChatAgendaService.enviarMensaje(
        texto,
        historial: historial,
        porVoz: porVoz,
      );
      respuesta = r.texto;
      respuestaVoz = r.textoVoz;
      accion = r.accion;
    }

    if (!mounted) return;

    setState(() {
      _mensajes.add({'role': 'bot', 'text': respuesta});
      _cargando = false;
      _accionPendiente =
          (accion != null && accion['tipo'] == 'confirmar_cita') ? accion : null;
    });
    _scrollHaciaAbajo();

    if (porVoz) _hablar(respuestaVoz ?? respuesta);
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

  // ───────────────────────────── Widgets ─────────────────────────────

  Widget _buildSugerencias() {
    final sugerencias = _sugerencias;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sugerencias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          // Chip propio (no ActionChip) para que el tema global de la app
          // no le ponga fondo blanco.
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _enviarMensaje(sugerido: sugerencias[i]),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _ChatColors.chipFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ChatColors.chipBorder),
                ),
                child: Text(
                  sugerencias[i],
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

  /// Botones que aparecen bajo el resumen de la cita.
  Widget _buildAccionConfirmacion() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _confirmando ? null : () => _confirmarCita(),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Confirmar cita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ChatColors.accent,
                foregroundColor: _ChatColors.onAccent,
                disabledBackgroundColor: _ChatColors.chipFill,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _confirmando ? null : _cancelarPropuesta,
            style: OutlinedButton.styleFrom(
              foregroundColor: _ChatColors.text,
              side: const BorderSide(color: _ChatColors.inputBorder),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final mostrarSugerencias = _mensajes.length <= 1 && !_cargando;
    final hayAccion = _accionPendiente != null;

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
                        child: Icon(
                          _admin ? Icons.support_agent : Icons.directions_car_rounded,
                          color: _ChatColors.onAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _admin ? 'Asistente del Administrador' : 'Asesor Virtual',
                              style: const TextStyle(
                                color: _ChatColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _admin
                                  ? 'Datos del negocio en vivo • Solo para ti'
                                  : 'En línea • Escribe o habla con el 🎤',
                              style: const TextStyle(
                                color: _ChatColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length + (hayAccion ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Último elemento: botones de confirmar / cambiar la cita
                      if (index == _mensajes.length) {
                        return _buildAccionConfirmacion();
                      }

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
                if (_cargando || _confirmando)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _ChatColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _confirmando
                              ? 'Agendando tu cita...'
                              : (_admin
                                  ? 'El asistente está consultando los datos...'
                                  : 'El asesor está respondiendo...'),
                          style: const TextStyle(color: _ChatColors.textMuted, fontSize: 12),
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
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: _escuchando
                                  ? 'Te escucho... habla ahora 🎤'
                                  : (_admin
                                      ? 'Pregunta por citas, pagos o servicios...'
                                      : 'Escribe o toca el micrófono...'),
                              hintStyle: const TextStyle(
                                  color: _ChatColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Micrófono: dicta el mensaje y lo envía al terminar de hablar
                      IconButton(
                        onPressed: _alternarMicrofono,
                        tooltip: _escuchando ? 'Detener' : 'Hablar',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              _escuchando ? Colors.redAccent : _ChatColors.inputFill,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: Icon(
                          _escuchando ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _escuchando ? Colors.white : _ChatColors.accent,
                          size: 20,
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