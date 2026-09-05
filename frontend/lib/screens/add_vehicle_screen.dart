import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wash_api_service.dart';
import '../theme/app_theme.dart';

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
    try {
      final XFile? imagen = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = imagen;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.azulElectrico),
              title: const Text('Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppTheme.azulElectrico),
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
            const SnackBar(
              content: Text('Error: Usuario no autenticado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _subiendo = false);
        return;
      }

      String? imagenUrl = _imagenUrlExistente;

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

      final bool esEdicion = widget.vehicleToEdit != null;

      if (esEdicion) {
        datosVehiculo['id'] = widget.vehicleToEdit!['_id'] ?? widget.vehicleToEdit!['id'];
      }

      final bool exito = await WashApiService.registrarVehiculo(datosVehiculo);

      if (mounted) {
        setState(() => _subiendo = false);
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                esEdicion
                    ? 'Vehículo actualizado correctamente'
                    : 'Vehículo guardado correctamente',
              ),
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.vehicleToEdit != null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Vehículo' : 'Registrar Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _mostrarOpcionesImagen,
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.azulElectrico.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: _imagenSeleccionada != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_imagenSeleccionada!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : (_imagenUrlExistente != null && _imagenUrlExistente!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _imagenUrlExistente!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (ctx, err, stack) => const Center(
                                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 42,
                                      color: AppTheme.azulElectrico,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toca para agregar foto del vehículo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _placaController,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      hintText: 'Ej. ABC123',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Ingresa la placa del vehículo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      hintText: 'Ej. Toyota',
                      prefixIcon: Icon(Icons.branding_watermark_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Ingresa la marca' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo / Referencia',
                      hintText: 'Ej. Corolla 2022',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Ingresa el modelo o referencia' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.azulElectrico,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _subiendo ? null : _guardarVehiculo,
                    child: _subiendo
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            esEdicion ? 'Actualizar Vehículo' : 'Guardar Vehículo',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}