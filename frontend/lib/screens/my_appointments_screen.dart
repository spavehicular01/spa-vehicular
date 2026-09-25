import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final String? token;

  const MyAppointmentsScreen({
    super.key,
    required this.usuario,
    this.token,
  });

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<dynamic> _citas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final userId = widget.usuario['id'] ?? widget.usuario['_id'];

    if (userId == null) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo identificar al usuario';
        });
      }
      return;
    }

    final res = await AppointmentService.obtenerCitasPorUsuario(
      userId.toString(),
      token: widget.token,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _citas = (res['citas'] as List?) ?? [];
        _cargando = false;
      });
    } else {
      setState(() {
        _cargando = false;
        _error = res['message']?.toString() ?? 'Error al cargar tus citas';
      });
    }
  }

  Future<void> _cancelarCita(String citaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final res = await AppointmentService.cancelarCita(citaId, token: widget.token);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Cita cancelada'),
          backgroundColor: Colors.red,
        ),
      );
      _cargarCitas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'No se pudo cancelar la cita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extrae un campo de forma segura sin importar cómo esté nombrado en el backend
  String _campo(dynamic cita, List<String> llaves) {
    if (cita is Map) {
      for (final llave in llaves) {
        final valor = cita[llave];
        if (valor != null && valor.toString().isNotEmpty) {
          return valor.toString();
        }
      }
    }
    return '';
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
      case 'confirmado':
      case 'aceptada':
        return Colors.green;
      case 'cancelada':
      case 'cancelado':
        return Colors.red;
      case 'completada':
      case 'completado':
        return Colors.blueGrey;
      case 'pendiente':
      default:
        return Colors.orange;
    }
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
        title: const Text('Mis Citas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.azulElectrico,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.azulElectrico))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: textColor)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarCitas,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.azulElectrico, foregroundColor: Colors.white),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _citas.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _cargarCitas,
                      color: AppTheme.azulElectrico,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy, size: 80, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tienes citas agendadas.',
                                    style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarCitas,
                      color: AppTheme.azulElectrico,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _citas.length,
                        itemBuilder: (context, index) {
                          final cita = _citas[index];
                          final String id = _campo(cita, ['_id', 'id']);
                          final String fecha = _campo(cita, ['fecha', 'date', 'selectedDate']);
                          final String hora = _campo(cita, ['hora', 'time', 'selectedTime']);
                          final String servicio = _campo(cita, ['servicio', 'nombreServicio', 'service', 'title']);
                          final String estado = _campo(cita, ['estado', 'status']).isNotEmpty
                              ? _campo(cita, ['estado', 'status'])
                              : 'pendiente';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        servicio.isNotEmpty ? servicio : 'Servicio de lavado',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _colorEstado(estado).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        estado[0].toUpperCase() + estado.substring(1),
                                        style: TextStyle(color: _colorEstado(estado), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      fecha.isNotEmpty ? fecha : 'Sin fecha',
                                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      hora.isNotEmpty ? hora : '--',
                                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                if (estado.toLowerCase() != 'cancelada' &&
                                    estado.toLowerCase() != 'cancelado' &&
                                    estado.toLowerCase() != 'completada' &&
                                    estado.toLowerCase() != 'completado') ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: id.isEmpty ? null : () => _cancelarCita(id),
                                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                      label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}