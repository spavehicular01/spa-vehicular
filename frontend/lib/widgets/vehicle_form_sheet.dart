import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import 'custom_button.dart';
import 'custom_input.dart';

class VehicleFormSheet extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final String? token;
  final VoidCallback onSuccess;

  const VehicleFormSheet({
    super.key,
    required this.usuario,
    this.token,
    required this.onSuccess,
  });

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _placaCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();

  final Map<String, String> _tiposVehiculo = {
    'Automóvil': 'automovil',
    'Motocicleta': 'moto',
    'Camioneta': 'camioneta',
    'SUV': 'SUV',
  };

  String _tipoSeleccionado = 'Automóvil';
  bool _enviando = false;

  @override
  void dispose() {
    _placaCtrl.dispose();
    _marcaCtrl.dispose();
    _referenciaCtrl.dispose();
    _modeloCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_placaCtrl.text.trim().isEmpty ||
        _marcaCtrl.text.trim().isEmpty ||
        _referenciaCtrl.text.trim().isEmpty ||
        _modeloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _enviando = true);

    final userId = widget.usuario['id'] ?? widget.usuario['_id'];
    final res = await VehicleService.registrarVehiculo(
      usuarioId: userId,
      placa: _placaCtrl.text.trim().toUpperCase(),
      marca: _marcaCtrl.text.trim(),
      referencia: _referenciaCtrl.text.trim(),
      modelo: _modeloCtrl.text.trim(),
      tipoVehiculo: _tiposVehiculo[_tipoSeleccionado]!,
      token: widget.token,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] == true) {
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo registrado correctamente'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Error al registrar'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                const Text('Registrar Vehículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            CustomInput(label: 'Placa (Ej: ABC123)', icon: Icons.badge_outlined, controller: _placaCtrl),
            const SizedBox(height: 12),
            CustomInput(label: 'Marca (Ej: Toyota)', icon: Icons.branding_watermark_outlined, controller: _marcaCtrl),
            const SizedBox(height: 12),
            CustomInput(label: 'Referencia (Ej: Corolla)', icon: Icons.directions_car_outlined, controller: _referenciaCtrl),
            const SizedBox(height: 12),
            CustomInput(label: 'Modelo (Año Ej: 2022)', icon: Icons.calendar_today_outlined, controller: _modeloCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Tipo de Vehículo',
                prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.azulElectrico),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: _tiposVehiculo.keys.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _tipoSeleccionado = val);
              },
            ),
            const SizedBox(height: 20),
            CustomButton(text: 'Guardar Vehículo', isLoading: _enviando, onPressed: _guardar),
          ],
        ),
      ),
    );
  }
}