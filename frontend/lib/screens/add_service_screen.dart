import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_types.dart';
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
  late TextEditingController _referenciaController;
  late TextEditingController _modeloController;

  // Etiqueta que ve el usuario -> valor que se guarda (ver models/vehicle_types.dart)
  final Map<String, String> _tiposVehiculo = {
    for (final t in tiposVehiculo) t.etiqueta: t.valor,
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
    final XFile? imagen = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _imagenSeleccionada = imagen);
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.secondary),
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

  Future<void> _guardarVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _subiendo = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usuarioId = prefs.getString('userId');

      if (usuarioId == null || usuarioId.isEmpty) {
        if (mounted) {
          _mostrarMensaje('Error: Usuario no autenticado', error: true);
          setState(() => _subiendo = false);
        }
        return;
      }

      String? imagenUrl = _imagenUrlExistente;

      if (_imagenSeleccionada != null) {
        imagenUrl = await WashApiService.subirImagen(_imagenSeleccionada!);
      }

      final Map<String, dynamic> datosVehiculo = {
        'usuarioId': usuarioId,
        'placa': _placaController.text.trim().toUpperCase(),
        'marca': _marcaController.text.trim(),
        'referencia': _referenciaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'tipoVehiculo': _tiposVehiculo[_tipoSeleccionado]!,
        'imagenUrl': imagenUrl ?? '',
      };

      // Editar => PUT sobre el vehículo existente (no crea duplicados).
      // Nuevo  => POST /vehicles/registrar.
      final vehiculoId = widget.vehicleToEdit?['_id']?.toString();
      final bool exito = vehiculoId != null && vehiculoId.isNotEmpty
          ? await WashApiService.actualizarVehiculo(vehiculoId, datosVehiculo)
          : await WashApiService.registrarVehiculo(datosVehiculo);

      if (!mounted) return;
      setState(() => _subiendo = false);

      if (exito) {
        _mostrarMensaje('Vehículo guardado correctamente');
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje('Error al procesar el vehículo', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      _mostrarMensaje('Error: $e', error: true);
    }
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: AppTextStyles.bodyStrong),
      );

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.vehicleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Vehículo' : 'Registrar Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _mostrarOpcionesImagen,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imagenSeleccionada!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : (_imagenUrlExistente != null &&
                              _imagenUrlExistente!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imagenUrlExistente!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 40, color: AppColors.secondary),
                                SizedBox(height: 8),
                                Text(
                                  'Toca para agregar foto del vehículo',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),

              _etiqueta('Placa'),
              TextFormField(
                controller: _placaController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Ej. ABC123',
                  prefixIcon: Icon(Icons.pin, color: AppColors.secondary),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              _etiqueta('Marca'),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Toyota',
                  prefixIcon: Icon(Icons.directions_car, color: AppColors.secondary),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              _etiqueta('Referencia'),
              TextFormField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Corolla',
                  prefixIcon: Icon(Icons.label_outline, color: AppColors.secondary),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              _etiqueta('Modelo / Año'),
              TextFormField(
                controller: _modeloController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej. 2022',
                  prefixIcon: Icon(Icons.calendar_today, color: AppColors.secondary),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              _etiqueta('Tipo de Vehículo'),
              DropdownButtonFormField<String>(
                initialValue: _tipoSeleccionado,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category, color: AppColors.secondary),
                ),
                items: _tiposVehiculo.keys
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _tipoSeleccionado = val);
                },
              ),
              const SizedBox(height: 28),

              // Toma el cian con texto navy del elevatedButtonTheme
              ElevatedButton(
                onPressed: _subiendo ? null : _guardarVehiculo,
                child: _subiendo
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(esEdicion ? 'Actualizar Vehículo' : 'Guardar Vehículo'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
