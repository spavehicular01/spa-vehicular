import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import 'add_vehicle_screen.dart';

class VehiclesScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final String? token;

  const VehiclesScreen({super.key, required this.usuario, this.token});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<dynamic> _vehiculos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  String? get _userId =>
      (widget.usuario['id'] ?? widget.usuario['_id'])?.toString();

  Future<void> _cargarVehiculos() async {
    setState(() => _isLoading = true);

    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final vehiculos = await VehicleService.obtenerVehiculos(
      userId,
      token: widget.token,
    );

    if (!mounted) return;
    setState(() {
      _vehiculos = vehiculos;
      _isLoading = false;
    });
  }

  Future<void> _confirmarEliminar(String id) async {
    final confirmar = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final exito = await VehicleService.eliminarVehiculo(id, token: widget.token);
    if (!mounted) return;

    if (exito) {
      await _cargarVehiculos();
      if (!mounted) return;
      _mostrarMensaje('Vehículo eliminado');
    } else {
      _mostrarMensaje('No se pudo eliminar el vehículo', error: true);
    }
  }

  void _mostrarMensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Usa la misma pantalla de registro (con foto) que Perfil,
  /// y recarga la lista cuando el backend confirma el registro.
  Future<void> _abrirRegistro() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );

    if (creado == true) {
      await _cargarVehiculos();
    }
  }

  /// Abre AddVehicleScreen en modo edición (usa PUT /vehicles/:id).
  Future<void> _abrirEdicion(Map<String, dynamic> vehiculo) async {
    final editado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(vehicleToEdit: vehiculo),
      ),
    );

    if (editado == true) {
      await _cargarVehiculos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Vehículos')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: _cargarVehiculos,
              child: _vehiculos.isEmpty
                  ? ListView(
                      // ListView para que el pull-to-refresh funcione en vacío
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No tienes vehículos registrados.',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vehiculos.length,
                      itemBuilder: (context, index) {
                        final item = _vehiculos[index];
                        final tipo = (item['tipoVehiculo'] ?? '').toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.accent.withValues(alpha: 0.15),
                              child: Icon(
                                tipo == 'moto'
                                    ? Icons.two_wheeler
                                    : Icons.directions_car,
                                color: AppColors.secondary,
                              ),
                            ),
                            title: Text(
                              '${item['marca'] ?? ''} ${item['referencia'] ?? ''}',
                              style: AppTextStyles.bodyStrong,
                            ),
                            subtitle: Text(
                              'Placa: ${item['placa']} • Modelo: ${item['modelo'] ?? 'N/A'}',
                              style: AppTextStyles.body,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.secondary),
                                  onPressed: () => _abrirEdicion(
                                    Map<String, dynamic>.from(item as Map),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _confirmarEliminar(item['_id'].toString()),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      // Toma el cian con icono navy del floatingActionButtonTheme
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirRegistro,
        child: const Icon(Icons.add),
      ),
    );
  }
}