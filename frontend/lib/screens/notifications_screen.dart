import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Lista de notificaciones guardadas del cliente (cita agendada, cambios de estado, pagos).
class NotificationsScreen extends StatefulWidget {
  final String usuarioId;

  const NotificationsScreen({super.key, required this.usuarioId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await ApiService.obtenerNotificaciones(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _items = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar tus notificaciones.';
        _cargando = false;
      });
    }
  }

  Future<void> _marcarLeida(int index) async {
    final item = _items[index];
    if (item['leida'] == true) return;

    final id = (item['_id'] ?? item['id'])?.toString();
    if (id == null) return;

    setState(() => _items[index]['leida'] = true);
    await ApiService.marcarNotificacionLeida(id);
  }

  Future<void> _marcarTodas() async {
    final exito = await ApiService.marcarTodasLeidas(widget.usuarioId);
    if (!mounted) return;

    if (exito) {
      setState(() {
        for (final n in _items) {
          n['leida'] = true;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron marcar como leídas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _icono(String? tipo) {
    switch (tipo) {
      case 'cita_creada':
        return Icons.event_available;
      case 'cita_reprogramada':
        return Icons.update;
      case 'cambio_estado':
        return Icons.local_car_wash;
      case 'pago_registrado':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }

  String _formatearFecha(dynamic iso) {
    final fecha = DateTime.tryParse('$iso')?.toLocal();
    if (fecha == null) return '';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  Widget _mensajeCentrado(String texto) {
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(texto, textAlign: TextAlign.center, style: AppTextStyles.body),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hayNoLeidas = _items.any((n) => n['leida'] != true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (hayNoLeidas)
            TextButton(
              onPressed: _marcarTodas,
              child: const Text('Marcar todas', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: _cargar,
              child: _error != null
                  ? _mensajeCentrado(_error!)
                  : _items.isEmpty
                      ? _mensajeCentrado('Aún no tienes notificaciones.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final n = _items[index];
                            final noLeida = n['leida'] != true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: noLeida ? AppColors.accent.withValues(alpha: 0.12) : null,
                              child: ListTile(
                                onTap: () => _marcarLeida(index),
                                leading: Icon(
                                  _icono(n['tipo']?.toString()),
                                  color: AppColors.secondary,
                                ),
                                title: Text(
                                  (n['titulo'] ?? '').toString(),
                                  style: AppTextStyles.bodyStrong,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text((n['mensaje'] ?? '').toString(), style: AppTextStyles.body),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatearFecha(n['fecha']),
                                      style: AppTextStyles.body.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: noLeida
                                    ? const Icon(Icons.circle, size: 10, color: Colors.redAccent)
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}