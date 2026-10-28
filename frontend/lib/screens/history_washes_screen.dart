import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/wash_service.dart';
import '../theme/app_theme.dart';

class HistoryWashesScreen extends StatefulWidget {
  const HistoryWashesScreen({super.key});

  @override
  State<HistoryWashesScreen> createState() => _HistoryWashesScreenState();
}

class _HistoryWashesScreenState extends State<HistoryWashesScreen> {
  late Future<List<dynamic>> _futureHistorial;
  late Future<Map<String, dynamic>?> _futureResumen;

  // Período mostrado en el desglose por método: 'hoy' | 'semana' | 'mes'
  String _periodo = 'hoy';

  static const Map<String, String> _etiquetasPeriodo = {
    'hoy': 'Hoy',
    'semana': 'Semana',
    'mes': 'Mes',
  };

  static const Map<String, String> _etiquetasMetodo = {
    'efectivo': 'Efectivo',
    'transferencia': 'Transferencia',
    'nequi': 'Nequi',
    'daviplata': 'Daviplata',
    'tarjeta': 'Tarjeta',
  };

  static const Map<String, IconData> _iconosMetodo = {
    'efectivo': Icons.payments_outlined,
    'transferencia': Icons.swap_horiz,
    'nequi': Icons.smartphone,
    'daviplata': Icons.smartphone,
    'tarjeta': Icons.credit_card,
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureHistorial = WashApiService.getHistorialCitas();
    _futureResumen = _cargarResumen();
  }

  // Si el resumen falla, la lista del historial se sigue mostrando igual.
  Future<Map<String, dynamic>?> _cargarResumen() async {
    try {
      return await ApiService.obtenerResumenPagos();
    } catch (_) {
      return null;
    }
  }

  Future<void> _recargar() async {
    setState(() => _cargar());
    await Future.wait([
      _futureHistorial.catchError((_) => <dynamic>[]),
      _futureResumen,
    ]);
  }

  // ───────────── Formato ─────────────

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

  String _pagosTexto(int cantidad) => cantidad == 1 ? '1 pago' : '$cantidad pagos';

  // ───────────── Extracción de datos de la cita ─────────────

  String _extraerServicio(Map cita) {
    final directo = cita['servicio'];
    if (directo is String) return directo;

    final servicioObj = cita['servicioId'];
    if (servicioObj is Map) {
      final nombre = servicioObj['nombre'] ?? servicioObj['nombreServicio'];
      if (nombre != null) return nombre.toString();
    }
    return 'Servicio de Lavado';
  }

  String _extraerVehiculo(Map cita) {
    final directo = cita['vehiculo'];
    if (directo is String) return directo;

    final vehiculoObj = cita['vehiculoId'];
    if (vehiculoObj is Map) {
      final marca = vehiculoObj['marca'];
      final modelo = vehiculoObj['modelo'];
      final placa = vehiculoObj['placa'];
      final partes = [
        if (marca != null) marca,
        if (modelo != null) modelo,
      ].join(' ');
      if (partes.isNotEmpty && placa != null) return '$partes ($placa)';
      if (partes.isNotEmpty) return partes;
      if (placa != null) return '$placa';
    }
    return 'N/A';
  }

  String _extraerPrecio(Map cita) {
    final directo = cita['precio'];
    if (directo != null) return directo.toString();

    final servicioObj = cita['servicioId'];
    final vehiculoObj = cita['vehiculoId'];

    if (servicioObj is Map) {
      final precios = servicioObj['precios'];
      if (precios is List && precios.isNotEmpty) {
        final tipoVehiculo = vehiculoObj is Map ? vehiculoObj['tipoVehiculo'] : null;

        if (tipoVehiculo != null) {
          final match = precios.firstWhere(
            (p) => p is Map && p['tipoVehiculo'] == tipoVehiculo,
            orElse: () => null,
          );
          if (match != null && match['precio'] != null) {
            return match['precio'].toString();
          }
        }

        final primerPrecio = precios.first;
        if (primerPrecio is Map && primerPrecio['precio'] != null) {
          return primerPrecio['precio'].toString();
        }
      }
    }
    return '0';
  }

  String _extraerFecha(Map cita) {
    final directa = cita['fecha'];
    if (directa is String) return directa;

    final fechaHora = cita['fechaHoraCita'];
    if (fechaHora != null) {
      final dt = DateTime.tryParse(fechaHora.toString())?.toLocal();
      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }
    return '';
  }

  String _extraerHora(Map cita) {
    final directa = cita['hora'];
    if (directa is String) return directa;

    final fechaHora = cita['fechaHoraCita'];
    if (fechaHora != null) {
      final dt = DateTime.tryParse(fechaHora.toString())?.toLocal();
      if (dt != null) {
        final hora = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hora:${dt.minute.toString().padLeft(2, '0')} $ampm';
      }
    }
    return '';
  }

  // ───────────── Resumen de pagos ─────────────

  Widget _tarjetaPeriodo(String clave, Map<String, dynamic> datos) {
    final seleccionado = _periodo == clave;
    final total = (datos['total'] as num?) ?? 0;
    final cantidad = (datos['cantidad'] as num?)?.toInt() ?? 0;
    final colorTotal = context.isDark ? AppColors.accent : AppColors.secondary;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _periodo = clave),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionado ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
            color: seleccionado ? const Color(0x1A00E5FF) : null,
          ),
          child: Column(
            children: [
              Text(_etiquetasPeriodo[clave]!, style: AppTextStyles.body),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatearPesos(total),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: colorTotal,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _pagosTexto(cantidad),
                style: AppTextStyles.body.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaMetodo(String metodo, Map datos) {
    final total = (datos['total'] as num?) ?? 0;
    final cantidad = (datos['cantidad'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_iconosMetodo[metodo] ?? Icons.payments_outlined,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_etiquetasMetodo[metodo] ?? metodo}  ·  ${_pagosTexto(cantidad)}',
              style: AppTextStyles.body,
            ),
          ),
          Text(_formatearPesos(total), style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }

  Widget _buildResumen(Map<String, dynamic> resumen) {
    final datosPeriodo = Map<String, dynamic>.from(resumen[_periodo] ?? {});
    final porMetodo = Map<String, dynamic>.from(datosPeriodo['porMetodo'] ?? {});
    final pendientes = Map<String, dynamic>.from(resumen['pendientes'] ?? {});

    final pendienteTotal = (pendientes['total'] as num?) ?? 0;
    final pendienteCantidad = (pendientes['cantidad'] as num?)?.toInt() ?? 0;

    // Solo se listan los métodos con pagos en el período, en orden fijo
    final metodosConPagos = _etiquetasMetodo.keys
        .where((m) => porMetodo[m] != null && ((porMetodo[m]['cantidad'] as num?) ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tres tarjetas: tocar una cambia el período del desglose
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _tarjetaPeriodo('hoy', Map<String, dynamic>.from(resumen['hoy'] ?? {})),
                const SizedBox(width: 6),
                _tarjetaPeriodo('semana', Map<String, dynamic>.from(resumen['semana'] ?? {})),
                const SizedBox(width: 6),
                _tarjetaPeriodo('mes', Map<String, dynamic>.from(resumen['mes'] ?? {})),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Desglose por método del período elegido
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Por método de pago · ${_etiquetasPeriodo[_periodo]}',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 6),
                if (metodosConPagos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin pagos en este período.', style: AppTextStyles.body),
                  )
                else
                  ...metodosConPagos.map((m) => _filaMetodo(m, porMetodo[m] as Map)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Citas finalizadas que aún no se han cobrado
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Por cobrar', style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 2),
                      Text(
                        pendienteCantidad == 0
                            ? 'No hay lavadas finalizadas sin pago.'
                            : '${pendienteCantidad == 1 ? '1 lavada finalizada' : '$pendienteCantidad lavadas finalizadas'} sin pago registrado',
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatearPesos(pendienteTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _seccionResumen() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _futureResumen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
          );
        }

        final resumen = snapshot.data;
        if (resumen == null) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No se pudo cargar el resumen de pagos. Desliza hacia abajo para reintentar.',
                style: AppTextStyles.body,
              ),
            ),
          );
        }

        return _buildResumen(resumen);
      },
    );
  }

  // ───────────── Historial ─────────────

  Widget _tarjetaCita(Map cita) {
    final pagado = cita['estadoPago'] == 'pagado';
    final precioTexto = _extraerPrecio(cita);
    final precioNumero = num.tryParse(precioTexto);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        // Verde = completado, mismo código semántico que usamos
        // para el estado "finalizada" en Mis Lavadas y Admin.
        leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
        title: Text(_extraerServicio(cita), style: AppTextStyles.bodyStrong),
        subtitle: Text(
          'Fecha: ${_extraerFecha(cita)} - Hora: ${_extraerHora(cita)}\nVehículo: ${_extraerVehiculo(cita)}',
          style: AppTextStyles.body,
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              precioNumero != null ? _formatearPesos(precioNumero) : '\$$precioTexto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.isDark ? AppColors.accent : AppColors.secondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pagado ? 'Pagado' : 'Por cobrar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: pagado ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionHistorial() {
    return FutureBuilder<List<dynamic>>(
      future: _futureHistorial,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                const SizedBox(height: 10),
                Text(
                  'No se pudo cargar el historial.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _recargar, child: const Text('Reintentar')),
              ],
            ),
          );
        }

        final citas = snapshot.data ?? [];
        if (citas.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Aún no hay lavadas finalizadas.', style: AppTextStyles.body),
            ),
          );
        }

        return Column(
          children: citas.map((c) => _tarjetaCita(c as Map)).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // El fondo y el AppBar vienen del tema (claro/oscuro).
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes e Historial'),
      ),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: _recargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
              child: Text('Resumen de pagos', style: AppTextStyles.h2),
            ),
            _seccionResumen(),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 24, 4, 6),
              child: Text('Lavadas finalizadas', style: AppTextStyles.h2),
            ),
            _seccionHistorial(),
          ],
        ),
      ),
    );
  }
}