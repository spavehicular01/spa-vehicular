import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  List<dynamic> _clientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final clientes = await ApiService.obtenerClientes();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _obtenerNombre(dynamic cliente) {
    final nombreCompleto = cliente['nombreCompleto'];
    if (nombreCompleto != null && nombreCompleto.toString().trim().isNotEmpty) {
      return nombreCompleto;
    }
    return 'Cliente sin nombre';
  }

  String _obtenerCorreo(dynamic cliente) {
    return cliente['correoNormalizado'] ?? cliente['correo'] ?? cliente['Correo_Electronico'] ?? 'Sin correo';
  }

  String _obtenerTelefono(dynamic cliente) {
    return cliente['telefonoNormalizado'] ?? cliente['celular'] ?? cliente['telefono'] ?? 'Sin teléfono';
  }

  void _verDetallesCliente(dynamic cliente) {
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
                  backgroundColor: Color.fromARGB(255, 0, 17, 255),
                  radius: 24,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _obtenerNombre(cliente),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _obtenerCorreo(cliente),
                        style: TextStyle(color: const Color.fromARGB(255, 56, 63, 122)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('📄 Documento: ${cliente['documentoIdentidad'] ?? 'No registrado'}'),
            const SizedBox(height: 4),
            Text('📞 Teléfono: ${_obtenerTelefono(cliente)}'),
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
                        title: Text('${v['marca'] ?? ''} ${v['referencia'] ?? ''} (${v['placa'] ?? 'Sin placa'})'),
                        subtitle: Text('Modelo: ${v['modelo'] ?? 'N/A'} - Tipo: ${v['tipoVehiculo'] ?? 'N/A'}'),
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
        backgroundColor: const Color.fromARGB(255, 0, 0, 254),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarClientes,
              child: _clientes.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No hay clientes registrados.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _clientes.length,
                      itemBuilder: (context, index) {
                        final cliente = _clientes[index];
                        final int numVehiculos = (cliente['vehiculos'] as List? ?? []).length;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: const CircleAvatar(
                              backgroundColor: Color.fromARGB(255, 0, 42, 255),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              _obtenerNombre(cliente),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(_obtenerCorreo(cliente)),
                                Text('Tel: ${_obtenerTelefono(cliente)}'),
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
            ),
    );
  }
}