import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/appointment_service.dart';

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
  bool _isLoading = true;
  List<dynamic> _citas = [];

  // Azul eléctrico unificado de la marca (#0033FF)
  static const Color azulBrand = Color(0xFF0033FF);
  static const Color azulOscuro = Color(0xFF001A80);

  @override
  void initState() {
    super.initState();
    _obtenerCitas();
  }

  Future<void> _obtenerCitas() async {
    setState(() => _isLoading = true);
    final userId = widget.usuario['_id'] ?? widget.usuario['id'];

    final resultado = await AppointmentService.obtenerCitasPorUsuario(
      userId,
      token: widget.token,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success']) {
          _citas = resultado['citas'] ?? [];
        }
      });
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.amber.shade700;
      case 'completada':
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.redAccent;
      default:
        return azulBrand;
    }
  }

  Future<void> _cancelarCita(String citaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final res = await AppointmentService.cancelarCita(citaId, token: widget.token);

    if (!mounted) return;

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada con éxito'), backgroundColor: Colors.green),
      );
      _obtenerCitas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Error al cancelar la cita'), backgroundColor: Colors.redAccent),
      );
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
        backgroundColor: isDark ? const Color(0xFF1E293B) : azulBrand,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerCitas,
          ),
        ],
      ),
      body: Stack(
        children: [
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

          _isLoading
              ? const Center(child: CircularProgressIndicator(color: azulBrand))
              : _citas.isEmpty
                  ? _buildEmptyState(textColor)
                  : RefreshIndicator(
                      onRefresh: _obtenerCitas,
                      color: azulBrand,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _citas.length,
                        itemBuilder: (context, index) {
                          final cita = _citas[index];
                          final String citaId = cita['_id'] ?? cita['id'] ?? '';
                          final String servicio = cita['servicio'] ?? 'Servicio de Lavado';
                          final String vehiculo = cita['vehiculo'] ?? 'Vehículo registrado';
                          final String hora = cita['hora'] ?? '';
                          final String estado = cita['estado'] ?? 'Pendiente';
                          final String? direccion = cita['direccion'];

                          DateTime? fecha;
                          if (cita['fechaHoraCita'] != null) {
                            fecha = DateTime.tryParse(cita['fechaHoraCita']);
                          }

                          final String fechaTexto = fecha != null
                              ? '${fecha.day}/${fecha.month}/${fecha.year}'
                              : 'Fecha pendiente';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        servicio,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _obtenerColorEstado(estado).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _obtenerColorEstado(estado)),
                                      ),
                                      child: Text(
                                        estado,
                                        style: TextStyle(
                                          color: _obtenerColorEstado(estado),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: borderColor, height: 1),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.directions_car, vehiculo, isDark),
                                const SizedBox(height: 6),
                                _buildInfoRow(Icons.event, '$fechaTexto - $hora', isDark),
                                if (cita['modalidad'] != null) ...[
                                  const SizedBox(height: 6),
                                  _buildInfoRow(
                                    cita['modalidad'] == 'A domicilio' ? Icons.home : Icons.store,
                                    cita['modalidad'] + (direccion != null ? ' ($direccion)' : ''),
                                    isDark,
                                  ),
                                ],
                                if (estado.toLowerCase() == 'pendiente' && citaId.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _cancelarCita(citaId),
                                      icon: const Icon(Icons.cancel, size: 16, color: Colors.redAccent),
                                      label: const Text(
                                        'Cancelar cita',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                                      ),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: azulBrand),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 160,
              child: Lottie.asset(
                'assets/animations/water_waves.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.calendar_today_outlined,
                  size: 80,
                  color: azulBrand,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes citas agendadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando programes un lavado para tu vehículo, aparecerá en esta sección.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}