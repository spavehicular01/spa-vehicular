import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import '../widgets/vehicle_list_tile.dart';
import 'add_vehicle_screen.dart'; // Importa la pantalla que ya tienes en screens/

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

  Future<void> _cargarVehiculos() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.usuario['id'] ?? widget.usuario['_id'];
      final vehiculos = await VehicleService.obtenerVehiculos(userId, token: widget.token);
      if (mounted) {
        setState(() {
          _vehiculos = vehiculos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarSnackBar('Error al cargar vehículos: $e', Colors.red);
      }
    }
  }

  Future<void> _eliminarVehiculo(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este vehículo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final exito = await VehicleService.eliminarVehiculo(id, token: widget.token);
    if (!mounted) return;

    if (exito) {
      _cargarVehiculos();
      _mostrarSnackBar('Vehículo eliminado con éxito', Colors.green);
    } else {
      _mostrarSnackBar('No se pudo eliminar el vehículo', Colors.red);
    }
  }

  void _mostrarSnackBar(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  void _abrirFormulario() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddVehicleScreen(),
      ),
    );
    if (res == true) _cargarVehiculos();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('Mis Vehículos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.azulElectrico))
          : _vehiculos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 80, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No tienes vehículos registrados.', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarVehiculos,
                  color: AppTheme.azulElectrico,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _vehiculos.length,
                    itemBuilder: (context, index) {
                      final item = _vehiculos[index];
                      return VehicleListTile(
                        vehiculo: item,
                        isDark: isDark,
                        onDelete: () => _eliminarVehiculo(item['_id']),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.azulElectrico,
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}