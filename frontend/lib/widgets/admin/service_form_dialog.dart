import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/service_model.dart';
import '../../services/wash_api_service.dart';
import '../../theme/app_theme.dart';
import 'service_prices_fields.dart';

/// Formulario para crear o editar un servicio. Devuelve true si se guardó.
class ServiceFormDialog extends StatefulWidget {
  final ServiceModel? servicio;

  const ServiceFormDialog({super.key, this.servicio});

  static Future<bool?> mostrar(BuildContext context, {ServiceModel? servicio}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServiceFormDialog(servicio: servicio),
    );
  }

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final Map<String, TextEditingController> _precios;

  XFile? _imagen;
  bool _subiendo = false;

  bool get _esEdicion => widget.servicio != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.servicio?.nombre ?? '');
    final desc = widget.servicio?.descripcion ?? '';
    _descripcion = TextEditingController(text: desc == 'Sin descripción' ? '' : desc);
    _precios = crearControladoresPrecios(widget.servicio);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    for (final c in _precios.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _elegirImagen() async {
    final XFile? foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (foto != null) setState(() => _imagen = foto);
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final precios = leerPrecios(_precios);

    if (nombre.isEmpty) {
      _aviso('Escribe el nombre del servicio');
      return;
    }
    if (precios.isEmpty) {
      _aviso('Llena el precio de al menos un tipo de vehículo');
      return;
    }

    setState(() => _subiendo = true);

    String? urlFoto = widget.servicio?.imagenUrl;
    if (_imagen != null) {
      final subida = await WashApiService.subirImagen(_imagen!);
      if (subida != null) urlFoto = subida;
    }

    final bool exito = _esEdicion
        ? await WashApiService.actualizarServicio(
            id: widget.servicio!.id,
            nombre: nombre,
            descripcion: _descripcion.text.trim(),
            precios: precios,
            image: urlFoto,
          )
        : await WashApiService.crearLavado(
            nombre: nombre,
            descripcion: _descripcion.text.trim(),
            precios: precios,
            image: urlFoto,
          );

    if (!mounted) return;

    if (exito) {
      Navigator.pop(context, true);
    } else {
      setState(() => _subiendo = false);
      _aviso('Error al guardar en el servidor', error: true);
    }
  }

  Widget _fotoServicio() {
    final urlExistente = widget.servicio?.imagenUrl ?? '';

    Widget contenido;
    if (_imagen != null) {
      contenido = Image.file(File(_imagen!.path), fit: BoxFit.cover);
    } else if (urlExistente.isNotEmpty) {
      contenido = Image.network(
        urlExistente,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    } else {
      contenido = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, color: AppColors.secondary, size: 30),
          SizedBox(height: 6),
          Text('Agregar foto del lavado', style: TextStyle(fontSize: 12)),
        ],
      );
    }

    return GestureDetector(
      onTap: _subiendo ? null : _elegirImagen,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.secondary),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: contenido),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar Servicio' : 'Nuevo Servicio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fotoServicio(),
            const SizedBox(height: 12),
            TextField(
              controller: _nombre,
              enabled: !_subiendo,
              decoration: const InputDecoration(labelText: 'Nombre del servicio'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcion,
              enabled: !_subiendo,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            ServicePricesFields(controladores: _precios, enabled: !_subiendo),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _subiendo ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        // Sin colores propios: hereda el ElevatedButtonTheme global.
        ElevatedButton(
          onPressed: _subiendo ? null : _guardar,
          child: _subiendo
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                )
              : Text(_esEdicion ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}