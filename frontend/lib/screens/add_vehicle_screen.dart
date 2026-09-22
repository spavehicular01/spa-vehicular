import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wash_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

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
  late TextEditingController _referenciaController; // 🟢 NUEVO
  late TextEditingController _modeloController;

  // 🟢 NUEVO: el backend exige tipoVehiculo como campo obligatorio.
  final Map<String, String> _tiposVehiculo = {
    'Automóvil': 'automovil',
    'Motocicleta': 'moto',
    'Camioneta': 'camioneta',
    'SUV': 'SUV',
  };
  String _tipoSeleccionado = 'Automóvil';

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
    _referenciaController = TextEditingController(
      text: widget.vehicleToEdit?['referencia'] ?? '',
    );
    _modeloController = TextEditingController(
      text: widget.vehicleToEdit?['modelo'] ?? '',
    );

    // Si estamos editando, intenta preseleccionar el tipo de vehículo existente.
    final tipoExistente = widget.vehicleToEdit?['tipoVehiculo'];
    if (tipoExistente != null) {
      final entry = _tiposVehiculo.entries.firstWhere(
        (e) => e.value == tipoExistente,
        orElse: () => _tiposVehiculo.entries.first,
      );
      _tipoSeleccionado = entry.key;
    }

    _imagenUrlExistente = widget.vehicleToEdit?['imagenUrl'];
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _referenciaController.dispose();
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

      // Subir nueva foto si se seleccionó una
      if (_imagenSeleccionada != null) {
        imagenUrl = await WashApiService.subirImagen(_imagenSeleccionada!);
      }

      // 🔧 CORREGIDO: el backend espera 'usuarioId' (no 'usuario'), y
      // exige también 'referencia' y 'tipoVehiculo' como obligatorios.
      final Map<String, dynamic> datosVehiculo = {
        'usuarioId': usuarioId,
        'placa': _placaController.text.trim().toUpperCase(),
        'marca': _marcaController.text.trim(),
        'referencia': _referenciaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'tipoVehiculo': _tiposVehiculo[_tipoSeleccionado]!,
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
                    border: Border.all(
                        color: const Color.fromARGB(255, 0, 76, 255)),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagenSeleccionada!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : (_imagenUrlExistente != null &&
                              _imagenUrlExistente!.isNotEmpty)
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
                                Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.teal),
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
              // 🟢 NUEVO: campo Referencia, obligatorio en el backend.
              TextFormField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                  labelText: 'Referencia (Ej. Corolla)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo / Año (Ej. 2022)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              // 🟢 NUEVO: selector de Tipo de Vehículo, obligatorio en el backend.
              DropdownButtonFormField<String>(
                initialValue: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Vehículo',
                  border: OutlineInputBorder(),
                ),
                items: _tiposVehiculo.keys
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _tipoSeleccionado = val);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _subiendo ? null : _guardarVehiculo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 17, 255),
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