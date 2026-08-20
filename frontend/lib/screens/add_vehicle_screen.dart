import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, String>? vehicleToEdit;

  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _referenciaController;
  late TextEditingController _modeloController;
  late TextEditingController _colorController;

  // Opción seleccionada por defecto o traída desde la edición
  String? _tipoVehiculoSeleccionado;

  // Lista de tipos de vehículos disponibles
  final List<String> _tiposVehiculos = [
    'Moto',
    'Automóvil',
    'Camioneta',
    'Turbo',
    'Camión',
  ];

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.vehicleToEdit?['placa'] ?? '');
    _marcaController = TextEditingController(text: widget.vehicleToEdit?['marca'] ?? '');
    _referenciaController = TextEditingController(text: widget.vehicleToEdit?['referencia'] ?? '');
    _modeloController = TextEditingController(text: widget.vehicleToEdit?['modelo'] ?? '');
    _colorController = TextEditingController(text: widget.vehicleToEdit?['color'] ?? '');
    
    // Si viene un valor para editar, aseguramos que exista en la lista de opciones
    final tipoInicial = widget.vehicleToEdit?['tipo'];
    if (tipoInicial != null && _tiposVehiculos.contains(tipoInicial)) {
      _tipoVehiculoSeleccionado = tipoInicial;
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _referenciaController.dispose();
    _modeloController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final vehicleData = {
        'tipo': _tipoVehiculoSeleccionado!,
        'placa': _placaController.text.toUpperCase(),
        'marca': _marcaController.text,
        'referencia': _referenciaController.text,
        'modelo': _modeloController.text,
        'color': _colorController.text,
      };
      Navigator.pop(context, vehicleData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.vehicleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Vehículo' : 'Registrar Vehículo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Desplegable (Dropdown) para Tipo de Vehículo
              DropdownButtonFormField<String>(
                value: _tipoVehiculoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Vehículo',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Seleccione el tipo de vehículo'),
                items: _tiposVehiculos.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    _tipoVehiculoSeleccionado = nuevoValor;
                  });
                },
                validator: (val) => val == null ? 'Selecciona un tipo de vehículo' : null,
              ),
              const SizedBox(height: 16),

              // Placa
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa (ej. ABC123)',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Marca
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca (ej. Toyota, Mazda, Yamaha)',
                  prefixIcon: Icon(Icons.branding_watermark),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Referencia
              TextFormField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                  labelText: 'Referencia (ej. Hilux, NMAX, CX-30)',
                  prefixIcon: Icon(Icons.car_repair),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Modelo / Año
              TextFormField(
                controller: _modeloController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Modelo / Año (ej. 2024)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  prefixIcon: Icon(Icons.color_lens),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: Text(esEdicion ? 'Guardar Cambios' : 'Registrar Vehículo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}