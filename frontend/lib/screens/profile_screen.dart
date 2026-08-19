import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final String nombreCompleto;
  final String correo;
  final String documento;
  final String telefono;
  final String? fotoUrl;
  final VoidCallback onCerrarSesion;

  const ProfileScreen({
    super.key,
    required this.nombreCompleto,
    required this.correo,
    required this.documento,
    required this.telefono,
    this.fotoUrl,
    required this.onCerrarSesion,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Lista simulada de vehículos asociados al usuario
  final List<Map<String, String>> _misVehiculos = [
    {'placa': 'ABC-123', 'modelo': 'Mazda 3', 'tipo': 'Automóvil'},
    {'placa': 'XYZ-789', 'modelo': 'Toyota Hilux', 'tipo': 'Camioneta'},
  ];

  // Función para realizar llamada normal
  Future<void> _hacerLlamada(String numero) async {
    final Uri url = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarSnackBar('No se pudo abrir el marcador telefónico');
    }
  }

  // Función para abrir WhatsApp
  Future<void> _abrirWhatsApp(String numero) async {
    final String cleanNum = numero.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/57$cleanNum');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _mostrarSnackBar('No se pudo abrir WhatsApp');
    }
  }

  void _mostrarSnackBar(String msj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msj)),
    );
  }

  void _opcionesContacto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.teal),
                title: const Text('Llamada Telefónica Normal'),
                onTap: () {
                  Navigator.pop(ctx);
                  _hacerLlamada(widget.telefono);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('Enviar mensaje por WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirWhatsApp(widget.telefono);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Desplegable / Modal para ver "Mis Vehículos"
  void _mostrarMisVehiculos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
              if (_misVehiculos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No tienes vehículos registrados aún.'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _misVehiculos.length,
                  itemBuilder: (context, index) {
                    final car = _misVehiculos[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car, color: Colors.teal),
                        title: Text('${car['modelo']} - ${car['placa']}'),
                        subtitle: Text('Tipo: ${car['tipo']}'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarSnackBar('Apartado para registrar vehículos próximamente...');
                },
                icon: const Icon(Icons.add),
                label: const Text('Registrar Nuevo Vehículo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 10),
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal.shade100,
            backgroundImage: widget.fotoUrl != null ? NetworkImage(widget.fotoUrl!) : null,
            child: widget.fotoUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.teal)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.nombreCompleto,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.correo,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          const Divider(),

          // Documento de Identidad
          ListTile(
            leading: const Icon(Icons.badge, color: Colors.teal),
            title: const Text('Documento de Identidad'),
            subtitle: Text(widget.documento),
          ),

          // Número de Teléfono
          Card(
            elevation: 0,
            color: Colors.teal.shade50,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.teal),
              title: const Text('Número de Teléfono'),
              subtitle: Text(widget.telefono),
              trailing: const Icon(Icons.touch_app, color: Colors.teal),
              onTap: _opcionesContacto,
            ),
          ),

          // --- NUEVO: Cuadro / Botón Mis Vehículos ---
          Card(
            elevation: 0,
            color: Colors.teal.shade50,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.teal),
              title: const Text('Mis Vehículos'),
              subtitle: Text('${_misVehiculos.length} vehículo(s) registrado(s)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal),
              onTap: _mostrarMisVehiculos,
            ),
          ),

          const SizedBox(height: 24),

          // Botón Cerrar Sesión
          OutlinedButton.icon(
            onPressed: widget.onCerrarSesion,
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