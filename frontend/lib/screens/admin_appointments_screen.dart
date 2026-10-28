import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  List<dynamic> _citas = [];
  bool _cargando = true;

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

  Future<void> _cambiarEstadoCita(String citaId, String nuevoEstado, int index) async {
    final exito = await ApiService.actualizarEstadoCita(citaId, nuevoEstado);

    if (!mounted) return;

    if (exito) {
      setState(() {
        _citas[index]['estado'] = nuevoEstado;
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
  Future<void> _registrarPago(dynamic cita, String citaId, int index) async {
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
        _citas[index]['estadoPago'] = 'pagado';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💰 Pago registrado correctamente'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas (Admin)'),
        // Sin backgroundColor propio: hereda el AppBarTheme global.
      ),
      // Antes era AppColors.background (siempre claro). Ahora cambia con el modo.
      backgroundColor: context.pageColor,
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: context.brandText))
          : RefreshIndicator(
              color: context.brandText,
              backgroundColor: context.surfaceColor,
              onRefresh: _cargarCitas,
              child: _citas.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No hay citas registradas.',
                            style: AppTextStyles.body.copyWith(color: context.mutedColor),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _citas.length,
                      itemBuilder: (context, index) {
                        final cita = _citas[index];
                        final estadoActual = cita['estado'] ?? 'pendiente';
                        final citaId = cita['_id'] ?? cita['id'];
                        final pagado = cita['estadoPago'] == 'pagado';
                        final precio = cita['precio'];

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
                                  '📅 Fecha: ${_formatearFecha(cita['fechaHoraCita'], cita['hora'])}',
                                  style: AppTextStyles.body,
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
                                        onTap: () => _registrarPago(cita, citaId, index),
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
                                          _cambiarEstadoCita(citaId, nuevoEstado, index);
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
              value: _metodo,
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