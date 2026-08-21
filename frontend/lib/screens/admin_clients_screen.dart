import 'package:flutter/material.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final List<Map<String, dynamic>> _clientes = [
    {
      'id': '1',
      'nombres': 'Diego Beltrán',
      'correo': 'diegobeltran0207@gmail.com',
      'documento': '1077852343',
      'telefono': '3102581864',
      'vehiculos': [
        {'placa': 'ABC123', 'marca': 'Toyota', 'referencia': 'Hilux', 'modelo': '2022', 'color': 'Blanco'}
      ],
    },
    {
      'id': '2',
      'nombres': 'Carlos Rodríguez',
      'correo': 'carlos.rodriguez@gmail.com',
      'documento': '1088432190',
      'telefono': '3159876543',
      'vehiculos': [
        {'placa': 'XYZ789', 'marca': 'Mazda', 'referencia': '3', 'modelo': '2021', 'color': 'Gris'}
      ],
    },
    {
      'id': '3',
      'nombres': 'Ana Martínez',
      'correo': 'ana.martinez@gmail.com',
      'documento': '1099123456',
      'telefono': '3201234567',
      'vehiculos': [
        {'placa': 'KTM456', 'marca': 'Chevrolet', 'referencia': 'Onix', 'modelo': '2023', 'color': 'Rojo'},
        {'placa': 'RST987', 'marca': 'Renault', 'referencia': 'Duster', 'modelo': '2020', 'color': 'Negro'}
      ],
    },
  ];

  void _verDetallesCliente(Map<String, dynamic> cliente) {
    final List vehiculos = cliente['vehiculos'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 24,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente['nombres'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      cliente['correo'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text('📄 Documento: ${cliente['documento']}'),
            const SizedBox(height: 4),
            Text('📞 Teléfono: ${cliente['telefono']}'),
            const SizedBox(height: 16),
            const Text(
              'Vehículos Registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            vehiculos.isEmpty
                ? const Text('Sin vehículos registrados.')
                : Column(
                    children: vehiculos.map<Widget>((v) {
                      return ListTile(
                        leading: const Icon(Icons.directions_car, color: Colors.teal),
                        title: Text('${v['marca']} ${v['referencia']} (${v['placa']})'),
                        subtitle: Text('Modelo: ${v['modelo']} - Color: ${v['color']}'),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Clientes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _clientes.isEmpty
          ? const Center(child: Text('No hay clientes registrados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                final int numVehiculos = (cliente['vehiculos'] as List).length;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      cliente['nombres'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(cliente['correo']),
                        Text('Tel: ${cliente['telefono']}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text('$numVehiculos veh.'),
                      backgroundColor: Colors.teal.shade50,
                      labelStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _verDetallesCliente(cliente),
                  ),
                );
              },
            ),
    );
  }
}