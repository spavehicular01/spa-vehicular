import 'package:flutter/material.dart';
import '../models/vehicle_types.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
                  backgroundColor: AppColors.primary,
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
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(_obtenerCorreo(cliente), style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('📄 Documento: ${cliente['documentoIdentidad'] ?? 'No registrado'}', style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text('📞 Teléfono: ${_obtenerTelefono(cliente)}', style: AppTextStyles.body),
            const SizedBox(height: 16),
            Text(
              'Vehículos Registrados',
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.secondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            vehiculos.isEmpty
                ? Text('Sin vehículos registrados.', style: AppTextStyles.body)
                : Column(
                    children: vehiculos.map<Widget>((v) {
                      return ListTile(
                        leading: Icon(
                          iconoTipoVehiculo((v['tipoVehiculo'] ?? '').toString()),
                          color: AppColors.secondary,
                        ),
                        title: Text('${v['marca'] ?? ''} ${v['referencia'] ?? ''} (${v['placa'] ?? 'Sin placa'})'),
                        subtitle: Text('Modelo: ${v['modelo'] ?? 'N/A'} - Tipo: ${etiquetaTipoVehiculo((v['tipoVehiculo'] ?? 'N/A').toString())}'),
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
        // Sin backgroundColor propio: hereda el AppBarTheme global.
      ),
      backgroundColor: AppColors.background,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: _cargarClientes,
              child: _clientes.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(child: Text('No hay clientes registrados.', style: AppTextStyles.body)),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _clientes.length,
                      itemBuilder: (context, index) {
                        final cliente = _clientes[index];
                        final int numVehiculos = (cliente['vehiculos'] as List? ?? []).length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(_obtenerNombre(cliente), style: AppTextStyles.bodyStrong),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(_obtenerCorreo(cliente), style: AppTextStyles.body),
                                Text('Tel: ${_obtenerTelefono(cliente)}', style: AppTextStyles.body),
                              ],
                            ),
                            trailing: StatusChip(
                              label: '$numVehiculos veh.',
                              color: AppColors.secondary,
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
