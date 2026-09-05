import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar vehículos: $e'), backgroundColor: Colors.red),
        );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo eliminado con éxito'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el vehículo'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarFormularioRegistro() {
    final placaCtrl = TextEditingController();
    final marcaCtrl = TextEditingController();
    final referenciaCtrl = TextEditingController();
    final modeloCtrl = TextEditingController();

    final Map<String, String> tiposVehiculo = {
      'Automóvil': 'automovil',
      'Motocicleta': 'moto',
      'Camioneta': 'camioneta',
      'SUV': 'SUV',
    };

    String tipoSeleccionado = 'Automóvil';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Registrar Vehículo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: placaCtrl,
                      decoration: const InputDecoration(labelText: 'Placa (Ej: ABC123)', border: OutlineInputBorder()),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: marcaCtrl,
                      decoration: const InputDecoration(labelText: 'Marca (Ej: Toyota)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenciaCtrl,
                      decoration: const InputDecoration(labelText: 'Referencia (Ej: Corolla)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modeloCtrl,
                      decoration: const InputDecoration(labelText: 'Modelo (Año Ej: 2022)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo de Vehículo', border: OutlineInputBorder()),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: tiposVehiculo.keys.map((tipo) {
                        return DropdownMenuItem(value: tipo, child: Text(tipo));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => tipoSeleccionado = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.azulElectrico,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (placaCtrl.text.trim().isEmpty ||
                            marcaCtrl.text.trim().isEmpty ||
                            referenciaCtrl.text.trim().isEmpty ||
                            modeloCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        final userId = widget.usuario['id'] ?? widget.usuario['_id'];

                        final res = await VehicleService.registrarVehiculo(
                          usuarioId: userId,
                          placa: placaCtrl.text.trim(),
                          marca: marcaCtrl.text.trim(),
                          referencia: referenciaCtrl.text.trim(),
                          modelo: modeloCtrl.text.trim(),
                          tipoVehiculo: tiposVehiculo[tipoSeleccionado]!,
                          token: widget.token,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        if (res['success'] == true) {
                          _cargarVehiculos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehículo registrado correctamente'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Error al registrar'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('Guardar Vehículo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.azulElectrico))
          : _vehiculos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 80, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes vehículos registrados.',
                        style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
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
                      final tipo = item['tipoVehiculo'] ?? '';

                      return Card(
                        elevation: 2,
                        color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.azulElectrico.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              tipo == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                              color: AppTheme.azulElectrico,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            '${item['marca']} ${item['referencia'] ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Placa: ${item['placa']} • Modelo: ${item['modelo'] ?? 'N/A'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _eliminarVehiculo(item['_id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.azulElectrico,
        onPressed: _mostrarFormularioRegistro,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}