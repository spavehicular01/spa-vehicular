import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';

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

  void _cargarVehiculos() async {
    setState(() => _isLoading = true);
    final userId = widget.usuario['id'] ?? widget.usuario['_id'];
    final vehiculos = await VehicleService.obtenerVehiculos(userId, token: widget.token);
    setState(() {
      _vehiculos = vehiculos;
      _isLoading = false;
    });
  }

  void _eliminarVehiculo(String id) async {
    final exito = await VehicleService.eliminarVehiculo(id, token: widget.token);
    if (exito) {
      _cargarVehiculos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo eliminado')),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registrar Vehículo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: placaCtrl,
                      decoration: const InputDecoration(labelText: 'Placa (Ej: ABC123)', border: OutlineInputBorder()),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: marcaCtrl,
                      decoration: const InputDecoration(labelText: 'Marca (Ej: Toyota)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: referenciaCtrl,
                      decoration: const InputDecoration(labelText: 'Referencia (Ej: Corolla)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: modeloCtrl,
                      decoration: const InputDecoration(labelText: 'Modelo (Año Ej: 2022)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo de Vehículo', border: OutlineInputBorder()),
                      items: tiposVehiculo.keys.map((tipo) {
                        return DropdownMenuItem(value: tipo, child: Text(tipo));
                      }).toList(),
                      onChanged: (val) => setModalState(() => tipoSeleccionado = val!),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (placaCtrl.text.isEmpty || 
                            marcaCtrl.text.isEmpty || 
                            referenciaCtrl.text.isEmpty || 
                            modeloCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa todos los campos')),
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

                        if (res['success']) {
                          _cargarVehiculos();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('Guardar Vehículo'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
        backgroundColor: const Color.fromARGB(255, 0, 30, 255),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehiculos.isEmpty
              ? const Center(child: Text('No tienes vehículos registrados.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _vehiculos.length,
                  itemBuilder: (context, index) {
                    final item = _vehiculos[index];
                    final tipo = item['tipoVehiculo'] ?? '';
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          tipo == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                          color: const Color.fromARGB(255, 0, 30, 255),
                          size: 32,
                        ),
                        title: Text(
                          '${item['marca']} ${item['referencia'] ?? ''}',
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 0, 30, 255),
        onPressed: _mostrarFormularioRegistro,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}