import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/extras/ui_extras.dart'; // colorAcento(context)

/// Lista de notificaciones guardadas del cliente (cita agendada, cambios de estado, pagos).
/// Todos los colores salen del tema, así que se ve bien en modo claro y oscuro.
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
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorTexto.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acento = colorAcento(context);
    final colorTexto = theme.colorScheme.onSurface;
    final hayNoLeidas = _items.any((n) => n['leida'] != true);

    // El fondo y el AppBar vienen del tema (claro/oscuro).
    return Scaffold(
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
          ? Center(child: CircularProgressIndicator(color: acento))
          : RefreshIndicator(
              color: acento,
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

                            // No leída: la tarjeta del tema con un toque de cian encima
                            // (se mezcla con el color de la tarjeta, no con el fondo).
                            final colorTarjeta = noLeida
                                ? Color.alphaBlend(
                                    acento.withValues(alpha: 0.14),
                                    theme.cardColor,
                                  )
                                : theme.cardColor;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: colorTarjeta,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: noLeida
                                      ? acento.withValues(alpha: 0.5)
                                      : colorTexto.withValues(alpha: 0.08),
                                ),
                              ),
                              child: ListTile(
                                onTap: () => _marcarLeida(index),
                                leading: Icon(
                                  _icono(n['tipo']?.toString()),
                                  color: acento,
                                ),
                                title: Text(
                                  (n['titulo'] ?? '').toString(),
                                  style: TextStyle(
                                    color: colorTexto,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      (n['mensaje'] ?? '').toString(),
                                      style: TextStyle(
                                        color: colorTexto.withValues(alpha: 0.78),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatearFecha(n['fecha']),
                                      style: TextStyle(
                                        color: colorTexto.withValues(alpha: 0.55),
                                        fontSize: 12,
                                      ),
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