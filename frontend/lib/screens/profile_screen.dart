import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_vehicle_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _listaVehiculos = List.from(widget.vehiculos);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehiculos != widget.vehiculos) {
      _listaVehiculos = List.from(widget.vehiculos);
    }
  }

  /// Borra el token guardado y ejecuta el callback de cierre de sesión
  Future<void> _ejecutarCerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpia el token y todos los datos residuales de SharedPreferences
    
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
    int? index,
    StateSetter? setModalState,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(vehicleToEdit: vehiculo),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        if (index != null) {
          _listaVehiculos[index] = result;
        } else {
          _listaVehiculos.add(result);
        }
      });

      widget.onVehiculosChanged(_listaVehiculos);

      if (setModalState != null) {
        setModalState(() {});
      }
    }
  }

  void _eliminarVehiculo(int index, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: const Text('¿Estás seguro de que deseas eliminar este vehículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _listaVehiculos.removeAt(index);
              });
              
              widget.onVehiculosChanged(_listaVehiculos);
              setModalState(() {});
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarMisVehiculos() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      const Text(
                        '🚘 Mis Vehículos',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_listaVehiculos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No tienes vehículos registrados aún.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _listaVehiculos.length,
                      itemBuilder: (context, index) {
                        final car = _listaVehiculos[index];
                        final tipo = car['tipo'] ?? 'Vehículo';
                        final marca = car['marca'] ?? '';
                        final referencia = car['referencia'] ?? '';
                        final placa = car['placa'] ?? '';
                        final modelo = car['modelo'] ?? '';
                        final color = car['color'] ?? '';

                        return Card(
                          elevation: 1,
                          color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              Icons.directions_car, 
                              color: isDark ? const Color(0xFF60A5FA) : const Color.fromARGB(255, 0, 30, 255),
                            ),
                            title: Text('$marca $referencia ($placa)'),
                            subtitle: Text('Tipo: $tipo | Año: $modelo | Color: $color'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _abrirAgregarEditarVehiculo(
                                      vehiculo: car,
                                      index: index,
                                      setModalState: setModalState,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _eliminarVehiculo(index, setModalState);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _abrirAgregarEditarVehiculo(setModalState: setModalState);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Nuevo Vehículo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2563EB) : const Color.fromARGB(255, 0, 21, 178),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
    // Detectamos si la app está en modo oscuro
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores dinámicos para las tarjetas del perfil
    final Color cardBgColor = isDark ? const Color(0xFF0F172A) : Colors.teal.shade50;
    final Color iconColor = isDark ? const Color(0xFF60A5FA) : const Color.fromARGB(255, 0, 34, 255);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: isDark ? const Color(0xFF2563EB) : const Color.fromARGB(255, 0, 21, 255),
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            widget.nombreCompleto,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.correo,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey),
          ),
          const Divider(height: 30),

          ListTile(
            leading: Icon(Icons.badge, color: iconColor),
            title: const Text('Documento de Identidad'),
            subtitle: Text(widget.documento),
          ),

          // Tarjeta de Teléfono adaptable
          Card(
            elevation: 0,
            color: cardBgColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(Icons.phone_android, color: iconColor),
              title: const Text('Número de Teléfono'),
              subtitle: Text(widget.telefono),
              trailing: Icon(Icons.touch_app, color: iconColor),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone, color: Color.fromRGBO(0, 255, 229, 1)),
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

          // Tarjeta de Mis Vehículos adaptable
          Card(
            elevation: 0,
            color: cardBgColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(Icons.directions_car, color: iconColor),
              title: const Text('Mis Vehículos'),
              subtitle: Text('${_listaVehiculos.length} vehículo(s) registrado(s)'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
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