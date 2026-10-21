import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_types.dart';
import '../services/wash_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/addvehicles/image_source_sheet.dart';
import '../widgets/addvehicles/labeled_text_field.dart';
import '../widgets/addvehicles/loading_button.dart';
import '../widgets/addvehicles/vehicle_image_picker.dart';
import '../widgets/addvehicles/vehicle_type_dropdown.dart';

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

  bool get _esEdicion => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    _placaController = TextEditingController(text: v?['placa'] ?? '');
    _marcaController = TextEditingController(text: v?['marca'] ?? '');
    _referenciaController = TextEditingController(text: v?['referencia'] ?? '');
    _modeloController = TextEditingController(text: v?['modelo'] ?? '');

    final tipoExistente = v?['tipoVehiculo'];
    if (tipoExistente != null) {
      final entry = _tiposVehiculo.entries.firstWhere(
        (e) => e.value == tipoExistente,
        orElse: () => _tiposVehiculo.entries.first,
      );
      _tipoSeleccionado = entry.key;
    }

    _imagenUrlExistente = v?['imagenUrl'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Vehículo' : 'Registrar Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VehicleImagePicker(
                imagenSeleccionada: _imagenSeleccionada,
                imagenUrlExistente: _imagenUrlExistente,
                onTap: () => mostrarOpcionesImagen(
                  context,
                  onSelected: _seleccionarImagen,
                ),
              ),
              const SizedBox(height: 20),
              LabeledTextField(
                label: 'Placa',
                hint: 'Ej. ABC123',
                icon: Icons.pin,
                controller: _placaController,
                textCapitalization: TextCapitalization.characters,
              ),
              LabeledTextField(
                label: 'Marca',
                hint: 'Ej. Toyota',
                icon: Icons.directions_car,
                controller: _marcaController,
              ),
              LabeledTextField(
                label: 'Referencia',
                hint: 'Ej. Corolla',
                icon: Icons.label_outline,
                controller: _referenciaController,
              ),
              LabeledTextField(
                label: 'Modelo / Año',
                hint: 'Ej. 2022',
                icon: Icons.calendar_today,
                controller: _modeloController,
                keyboardType: TextInputType.number,
              ),
              VehicleTypeDropdown(
                value: _tipoSeleccionado,
                opciones: _tiposVehiculo.keys.toList(),
                onChanged: (val) => setState(() => _tipoSeleccionado = val),
              ),
              const SizedBox(height: 28),
              LoadingButton(
                label: _esEdicion ? 'Actualizar Vehículo' : 'Guardar Vehículo',
                loading: _subiendo,
                onPressed: _guardarVehiculo,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}