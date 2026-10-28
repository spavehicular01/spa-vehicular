import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ───────── Elementos de la lista (encabezados, avisos y citas) ─────────

class _EncabezadoDia {
  final String etiqueta;
  final int cantidad;
  final bool esHoy;
  const _EncabezadoDia(this.etiqueta, this.cantidad, this.esHoy);
}

class _BarraCompletadas {
  final int cantidad;
  const _BarraCompletadas(this.cantidad);
}

class _MensajeVacio {
  final String texto;
  const _MensajeVacio(this.texto);
}

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  static const List<String> _nombresDias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  List<dynamic> _citas = [];
  bool _cargando = true;

  // Las citas finalizadas Y pagadas se ocultan de la lista (no se borran).
  // Con este interruptor se pueden volver a mostrar.
  bool _mostrarCompletadas = false;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final citas = await ApiService.obtenerTodasLasCitas();
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar citas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Ahora se recibe la cita misma (y no su posición), porque la lista se
  // reordena y se agrupa por día y el índice ya no coincide con _citas.
  Future<void> _cambiarEstadoCita(String citaId, String nuevoEstado, dynamic cita) async {
    final exito = await ApiService.actualizarEstadoCita(citaId, nuevoEstado);

    if (!mounted) return;

    if (exito) {
      setState(() {
        cita['estado'] = nuevoEstado;
      });

      String mensaje = 'Estado actualizado a "$nuevoEstado"';
      if (nuevoEstado == 'en_proceso') {
        mensaje = '🧼 Notificación enviada: ¡Lavado iniciado!';
      } else if (nuevoEstado == 'finalizada') {
        mensaje = '✅ Notificación enviada: ¡Lavado finalizado!';
      } else if (nuevoEstado == 'cancelada') {
        mensaje = '❌ La cita ha sido cancelada.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado en el servidor'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🟢 Registrar el pago real de la cita (el cliente paga al recoger el vehículo)
  Future<void> _registrarPago(dynamic cita, String citaId) async {
    final precio = cita['precio'];

    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RegistrarPagoDialog(
        nombreCliente: _obtenerNombreUsuario(cita),
        montoInicial: precio is num ? precio.round() : null,
        metodoInicial: _metodoPrevisto(cita),
      ),
    );

    if (datos == null) return;

    final resultado = await ApiService.registrarPago(
      citaId: citaId,
      metodoPago: datos['metodoPago'] as String,
      monto: (datos['monto'] as int).toDouble(),
      referencia: datos['referencia'] as String?,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      setState(() {
        cita['estadoPago'] = 'pagado';
      });
      final seOculta = _esCompletada(cita) && !_mostrarCompletadas;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            seOculta
                ? '💰 Pago registrado. La cita pasó a completadas.'
                : '💰 Pago registrado correctamente',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${resultado['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convierte el texto que eligió el cliente al agendar en un método del backend
  String _metodoPrevisto(dynamic cita) {
    final texto = (cita['metodoPago'] ?? '').toString().toLowerCase();
    if (texto.contains('transferencia')) return 'transferencia';
    if (texto.contains('tarjeta')) return 'tarjeta';
    return 'efectivo';
  }

  String _formatearPesos(num valor) {
    final s = valor.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final restantes = s.length - i;
      buf.write(s[i]);
      if (restantes > 1 && restantes % 3 == 1) buf.write('.');
    }
    return '\$$buf';
  }

  // Colores semánticos por estado (se mantienen distintos entre sí
  // a propósito, para diferenciar estados de un vistazo).
  Color _obtenerColorEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return context.brandText; // azul agua en claro, cian en oscuro
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return context.mutedColor;
    }
  }

  String _obtenerNombreUsuario(dynamic cita) {
    final usuario = cita['usuarioId'];
    if (usuario is Map) {
      final nombre = usuario['nombres'] ?? usuario['Nombre'];
      final apellido = usuario['apellidos'] ?? usuario['Apellido'];
      if (nombre != null && nombre.toString().trim().isNotEmpty) {
        final apellidoStr = (apellido != null && apellido.toString().trim().isNotEmpty)
            ? ' $apellido'
            : '';
        return '$nombre$apellidoStr';
      }
    }
    return 'Cliente sin nombre';
  }

  String _obtenerDetalleVehiculo(dynamic cita) {
    if (cita['vehiculoId'] is Map) {
      final v = cita['vehiculoId'];
      return '${v['placa'] ?? ''} - ${v['marca'] ?? ''} ${v['modelo'] ?? ''}'.trim();
    }
    return cita['vehiculo'] ?? cita['vehiculoId'] ?? 'N/A';
  }

  String _obtenerDetalleServicio(dynamic cita) {
    if (cita['servicioId'] is Map) {
      // En la base de datos el nombre del servicio está en "nombreServicio"
      final servicio = cita['servicioId'];
      return (servicio['nombreServicio'] ?? servicio['nombre'] ?? 'Servicio Estándar').toString();
    }
    return cita['servicio'] ?? 'Servicio General';
  }

  String _formatearFecha(String? fechaIso, String? hora) {
    if (fechaIso == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaIso);
      final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
      return hora != null ? '$fechaStr ($hora)' : fechaStr;
    } catch (_) {
      return fechaIso;
    }
  }

  // ───────── Agrupar por día y ordenar por hora ─────────

  /// Una cita está "completada" cuando ya se lavó y ya se cobró.
  bool _esCompletada(dynamic cita) {
    return cita['estado'] == 'finalizada' && cita['estadoPago'] == 'pagado';
  }

  /// Fecha de la cita, leída igual que la muestra la tarjeta.
  DateTime? _fechaDeCita(dynamic cita) {
    final iso = cita['fechaHoraCita'];
    if (iso == null) return null;
    try {
      return DateTime.parse(iso.toString());
    } catch (_) {
      return null;
    }
  }

  /// Hora de la cita en minutos desde la medianoche, o null si no tiene hora.
  /// Entiende "14:30", "2:30 PM" y "02:30 p. m.". Si ningún campo de hora
  /// trae dato, la saca de fechaHoraCita (a menos que sea exactamente 00:00).
  int? _minutosDeCita(dynamic cita) {
    for (final clave in ['hora', 'horaCita', 'horaInicio', 'horario']) {
      final texto = (cita[clave] ?? '').toString().trim().toUpperCase();
      if (texto.isEmpty) continue;
      final m = RegExp(r'(\d{1,2})\s*[:.]\s*(\d{2})\s*([AP]\.?\s?M\.?)?').firstMatch(texto);
      if (m != null) {
        var horas = int.parse(m.group(1)!);
        final minutos = int.parse(m.group(2)!);
        final ampm = m.group(3);
        if (ampm != null) {
          final esPm = ampm.startsWith('P');
          if (esPm && horas < 12) horas += 12;
          if (!esPm && horas == 12) horas = 0;
        }
        return horas * 60 + minutos;
      }
    }
    final fecha = _fechaDeCita(cita);
    if (fecha == null || (fecha.hour == 0 && fecha.minute == 0)) return null;
    return fecha.hour * 60 + fecha.minute;
  }

  /// Para ordenar: las citas sin hora quedan al final del día.
  int _minutosDelDia(dynamic cita) => _minutosDeCita(cita) ?? 24 * 60;

  String _formatearHora(int minutos) {
    final h = minutos ~/ 60;
    final mm = (minutos % 60).toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm ${h >= 12 ? 'PM' : 'AM'}';
  }

  String _etiquetaDia(DateTime dia) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diferencia = dia.difference(hoy).inDays;
    final fecha = '${dia.day}/${dia.month}/${dia.year}';

    if (diferencia == 0) return 'Hoy · $fecha';
    if (diferencia == 1) return 'Mañana · $fecha';
    if (diferencia == -1) return 'Ayer · $fecha';
    return '${_nombresDias[dia.weekday - 1]} · $fecha';
  }

  bool _esHoy(DateTime dia) {
    final ahora = DateTime.now();
    return dia.year == ahora.year && dia.month == ahora.month && dia.day == ahora.day;
  }

  /// Arma la lista que se dibuja: aviso de completadas, y por cada día un
  /// encabezado seguido de sus citas ordenadas por hora.
  List<Object> _construirLista() {
    final totalCompletadas = _citas.where(_esCompletada).length;

    final visibles = _mostrarCompletadas
        ? List<dynamic>.from(_citas)
        : _citas.where((c) => !_esCompletada(c)).toList();

    final porDia = <DateTime, List<dynamic>>{};
    final sinFecha = <dynamic>[];

    for (final cita in visibles) {
      final fecha = _fechaDeCita(cita);
      if (fecha == null) {
        sinFecha.add(cita);
      } else {
        final dia = DateTime(fecha.year, fecha.month, fecha.day);
        porDia.putIfAbsent(dia, () => []).add(cita);
      }
    }

    final items = <Object>[];

    if (totalCompletadas > 0) {
      items.add(_BarraCompletadas(totalCompletadas));
    }

    final dias = porDia.keys.toList()..sort();
    for (final dia in dias) {
      final lista = porDia[dia]!;
      lista.sort((a, b) => _minutosDelDia(a).compareTo(_minutosDelDia(b)));
      items.add(_EncabezadoDia(_etiquetaDia(dia), lista.length, _esHoy(dia)));
      items.addAll(lista.cast<Object>());
    }

    if (sinFecha.isNotEmpty) {
      items.add(_EncabezadoDia('Sin fecha', sinFecha.length, false));
      items.addAll(sinFecha.cast<Object>());
    }

    if (visibles.isEmpty) {
      items.add(_MensajeVacio(
        _citas.isEmpty
            ? 'No hay citas registradas.'
            : 'No hay citas pendientes.\nLas completadas están ocultas.',
      ));
    }

    return items;
  }

  // ───────── Widgets ─────────

  Widget _construirBarraCompletadas(_BarraCompletadas barra) {
    final n = barra.cantidad;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _mostrarCompletadas
                  ? 'Mostrando $n completadas'
                  : '$n completadas ocultas',
              style: AppTextStyles.body.copyWith(color: context.mutedColor),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _mostrarCompletadas = !_mostrarCompletadas),
            child: Text(_mostrarCompletadas ? 'Ocultar' : 'Mostrar'),
          ),
        ],
      ),
    );
  }

  Widget _construirEncabezadoDia(_EncabezadoDia encabezado) {
    final color = encabezado.esHoy ? context.brandText : context.textColor;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10, left: 2, right: 2),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              encabezado.etiqueta,
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 16, color: color),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Text(
              '${encabezado.cantidad} ${encabezado.cantidad == 1 ? 'cita' : 'citas'}',
              style: TextStyle(fontSize: 12, color: context.mutedColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaCita(dynamic cita) {
    final estadoActual = cita['estado'] ?? 'pendiente';
    final citaId = cita['_id'] ?? cita['id'];
    final pagado = cita['estadoPago'] == 'pagado';
    final precio = cita['precio'];
    final minutosHora = _minutosDeCita(cita);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _obtenerNombreUsuario(cita),
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(
                  label: estadoActual,
                  color: _obtenerColorEstado(estadoActual),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('🧼 Servicio: ${_obtenerDetalleServicio(cita)}', style: AppTextStyles.body),
            Text('🚗 Vehículo: ${_obtenerDetalleVehiculo(cita)}', style: AppTextStyles.body),
            Text(
              '📅 Fecha: ${_formatearFecha(cita['fechaHoraCita'], null)}',
              style: AppTextStyles.body,
            ),
            Text(
              minutosHora != null
                  ? '🕒 Hora: ${_formatearHora(minutosHora)}'
                  : '🕒 Hora: sin hora registrada',
              style: AppTextStyles.bodyStrong.copyWith(
                color: minutosHora != null ? context.brandText : Colors.orange,
              ),
            ),
            if (cita['modalidad'] != null)
              Text(
                '📍 Modalidad: ${cita['modalidad'] == 'domicilio' ? 'A Domicilio' : 'En Spa'}',
                style: AppTextStyles.body,
              ),
            if (estadoActual != 'cancelada')
              Text(
                '💰 Pago: ${pagado ? 'Pagado' : 'Pendiente'}'
                '${precio is num ? ' · ${_formatearPesos(precio)}' : ''}',
                style: AppTextStyles.body,
              ),
            Divider(height: 24, color: context.borderColor),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // 🟢 Solo aparece cuando el lavado terminó y aún no se ha cobrado
                if (estadoActual == 'finalizada' && !pagado && citaId != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _registrarPago(cita, citaId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Registrar pago',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (nuevoEstado) {
                    if (citaId != null) {
                      _cambiarEstadoCita(citaId, nuevoEstado, cita);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'en_proceso',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: context.brandText),
                          const SizedBox(width: 8),
                          const Text('Iniciar Lavada (En Proceso)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'finalizada',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Finalizar Lavada (Completado)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancelada',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancelar Cita'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cambiar Estado',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _cargando ? const <Object>[] : _construirLista();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas (Admin)'),
        // Sin backgroundColor propio: hereda el AppBarTheme global.
      ),
      backgroundColor: context.pageColor,
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: context.brandText))
          : RefreshIndicator(
              color: context.brandText,
              backgroundColor: context.surfaceColor,
              onRefresh: _cargarCitas,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (item is _BarraCompletadas) {
                    return _construirBarraCompletadas(item);
                  }
                  if (item is _EncabezadoDia) {
                    return _construirEncabezadoDia(item);
                  }
                  if (item is _MensajeVacio) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 120),
                      child: Center(
                        child: Text(
                          item.texto,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(color: context.mutedColor),
                        ),
                      ),
                    );
                  }
                  return _construirTarjetaCita(item);
                },
              ),
            ),
    );
  }
}

// 🟢 Diálogo para registrar el pago: método real, monto y referencia opcional.
class _RegistrarPagoDialog extends StatefulWidget {
  final String nombreCliente;
  final int? montoInicial;
  final String metodoInicial;

  const _RegistrarPagoDialog({
    required this.nombreCliente,
    required this.montoInicial,
    required this.metodoInicial,
  });

  @override
  State<_RegistrarPagoDialog> createState() => _RegistrarPagoDialogState();
}

class _RegistrarPagoDialogState extends State<_RegistrarPagoDialog> {
  static const Map<String, String> _metodos = {
    'efectivo': 'Efectivo',
    'transferencia': 'Transferencia',
    'nequi': 'Nequi',
    'daviplata': 'Daviplata',
    'tarjeta': 'Tarjeta Débito / Crédito',
  };

  late String _metodo;
  late final TextEditingController _montoCtrl;
  final TextEditingController _referenciaCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _metodo = _metodos.containsKey(widget.metodoInicial) ? widget.metodoInicial : 'efectivo';
    _montoCtrl = TextEditingController(
      text: widget.montoInicial != null ? widget.montoInicial.toString() : '',
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final monto = int.tryParse(_montoCtrl.text.trim());
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }

    Navigator.of(context).pop({
      'metodoPago': _metodo,
      'monto': monto,
      'referencia': _metodo == 'efectivo' ? null : _referenciaCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${widget.nombreCliente}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _metodo,
              dropdownColor: context.surfaceColor,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: _metodos.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (valor) {
                if (valor != null) setState(() => _metodo = valor);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Monto cobrado',
                prefixText: '\$ ',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_metodo != 'efectivo') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _referenciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia o comprobante (opcional)',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}