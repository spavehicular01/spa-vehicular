import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wash_api_service.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicleToEdit;

  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;

  XFile? _imagenSeleccionada;
  String? _imagenUrlExistente;
  bool _subiendo = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(
      text: widget.vehicleToEdit?['placa'] ?? '',
    );
    _marcaController = TextEditingController(
      text: widget.vehicleToEdit?['marca'] ?? '',
    );
    _modeloController = TextEditingController(
      text: widget.vehicleToEdit?['modelo'] ?? '',
    );
    _imagenUrlExistente = widget.vehicleToEdit?['imagenUrl'];
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? imagen = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = imagen;
      });
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.of(context).pop();
                _seleccionarImagen(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _subiendo = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usuarioId = prefs.getString('userId');

      if (usuarioId == null || usuarioId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Usuario no autenticado')),
          );
        }
        setState(() => _subiendo = false);
        return;
      }

      String? imagenUrl = _imagenUrlExistente;
      
      // Subir nueva foto si se seleccionó una
      if (_imagenSeleccionada != null) {
        imagenUrl = await WashApiService.subirImagen(_imagenSeleccionada!);
      }

      final Map<String, dynamic> datosVehiculo = {
        'usuario': usuarioId,
        'placa': _placaController.text.trim().toUpperCase(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'imagenUrl': imagenUrl ?? '',
      };

      final exito = await WashApiService.registrarVehiculo(datosVehiculo);

      if (mounted) {
        setState(() => _subiendo = false);
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo guardado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al procesar el vehículo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subiendo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _mostrarOpcionesImagen,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagenSeleccionada!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : (_imagenUrlExistente != null && _imagenUrlExistente!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imagenUrlExistente!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.teal),
                                SizedBox(height: 8),
                                Text('Toca para agregar foto del vehículo'),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa (Ej. ABC123)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca (Ej. Toyota)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo (Ej. Corolla 2022)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _subiendo ? null : _guardarVehiculo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _subiendo
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          esEdicion ? 'Actualizar Vehículo' : 'Guardar Vehículo',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}