import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_vehicle_screen.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String nombreCompleto;
  final String correo;
  final String documento;
  final String telefono;
  final List<Map<String, String>> vehiculos;
  final Function(List<Map<String, String>>) onVehiculosChanged;
  final VoidCallback onCerrarSesion;

  const ProfileScreen({
    super.key,
    required this.nombreCompleto,
    required this.correo,
    required this.documento,
    required this.telefono,
    required this.vehiculos,
    required this.onVehiculosChanged,
    required this.onCerrarSesion,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<Map<String, String>> _listaVehiculos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _listaVehiculos = List.from(widget.vehiculos);
    _cargarVehiculos();
  }

  /// Fuente de verdad: el backend. Se llama al abrir y después de
  /// registrar o eliminar un vehículo.
  Future<void> _cargarVehiculos({StateSetter? setModalState}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('token');

    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    final raw = await VehicleService.obtenerVehiculos(userId, token: token);

    // Todo se convierte a Map<String, String> (incluye '_id' y 'tipoVehiculo').
    final lista = raw.whereType<Map>().map<Map<String, String>>((v) {
      return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
    }).toList();

    if (!mounted) return;
    setState(() {
      _listaVehiculos = lista;
      _cargando = false;
    });

    try {
      setModalState?.call(() {});
    } catch (_) {
      // El bottom sheet ya se cerró; no pasa nada.
    }

    widget.onVehiculosChanged(lista);
  }

  Future<void> _ejecutarCerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    widget.onCerrarSesion();
  }

  Future<void> _hacerLlamada(String numero) async {
    final Uri url = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _abrirWhatsApp(String numero) async {
    final String cleanNum = numero.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/57$cleanNum');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _abrirAgregarEditarVehiculo({
    Map<String, String>? vehiculo,
    StateSetter? setModalState,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(vehicleToEdit: vehiculo),
      ),
    );

    // AddVehicleScreen devuelve `true` cuando el backend confirmó el registro.
    if (result == true) {
      await _cargarVehiculos(setModalState: setModalState);
    }
  }

  void _eliminarVehiculo(Map<String, String> car, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar vehículo', style: AppTextStyles.h2),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este vehículo?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final id = car['_id'] ?? car['id'] ?? '';
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');

              final ok = await VehicleService.eliminarVehiculo(id, token: token);

              if (!mounted) return;
              if (ok) {
                await _cargarVehiculos(setModalState: setModalState);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo eliminar el vehículo'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarMisVehiculos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🚘 Mis Vehículos', style: AppTextStyles.h2),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.secondary),
                      ),
                    )
                  else if (_listaVehiculos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No tienes vehículos registrados aún.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _listaVehiculos.length,
                        itemBuilder: (context, index) {
                          final car = _listaVehiculos[index];
                          final tipo = car['tipoVehiculo'] ?? 'Vehículo';
                          final marca = car['marca'] ?? '';
                          final referencia = car['referencia'] ?? '';
                          final placa = car['placa'] ?? '';
                          final modelo = car['modelo'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                tipo == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                                color: AppColors.secondary,
                              ),
                              title: Text('$marca $referencia ($placa)'),
                              subtitle: Text('Tipo: $tipo | Año: $modelo'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.secondary),
                                    onPressed: () => _abrirAgregarEditarVehiculo(
                                      vehiculo: car,
                                      setModalState: setModalState,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarVehiculo(car, setModalState),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _abrirAgregarEditarVehiculo(setModalState: setModalState);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Nuevo Vehículo'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(widget.nombreCompleto, style: AppTextStyles.h2),
          Text(widget.correo, style: AppTextStyles.body),
          const Divider(height: 30),

          ListTile(
            leading: const Icon(Icons.badge, color: AppColors.secondary),
            title: const Text('Documento de Identidad'),
            subtitle: Text(widget.documento),
          ),

          Card(
            elevation: 0,
            color: const Color(0x1A00E5FF),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.phone_android, color: AppColors.secondary),
              title: const Text('Número de Teléfono'),
              subtitle: Text(widget.telefono),
              trailing: const Icon(Icons.touch_app, color: AppColors.secondary),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone, color: AppColors.secondary),
                        title: const Text('Llamar'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _hacerLlamada(widget.telefono);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.chat, color: Colors.green),
                        title: const Text('WhatsApp'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _abrirWhatsApp(widget.telefono);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Card(
            elevation: 0,
            color: const Color(0x1A00E5FF),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: AppColors.secondary),
              title: const Text('Mis Vehículos'),
              subtitle: Text(
                _cargando
                    ? 'Cargando...'
                    : '${_listaVehiculos.length} vehículo(s) registrado(s)',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.secondary),
              onTap: _mostrarMisVehiculos,
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _ejecutarCerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }
}