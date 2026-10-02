import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'avatar_picker.dart';
import 'profile_form_fields.dart';
import 'profile_utils.dart';
import 'save_button.dart';

/// Formulario para editar nombres, apellidos, celular y foto.
/// Devuelve (Navigator.pop) el usuario actualizado que respondió el backend.
class EditProfileSheet extends StatefulWidget {
  final String nombres;
  final String apellidos;
  final String celular;
  final String avatarUrl;

  const EditProfileSheet({
    super.key,
    required this.nombres,
    required this.apellidos,
    required this.celular,
    required this.avatarUrl,
  });

  /// Abre el formulario como bottom sheet y devuelve el usuario actualizado
  /// (o null si el usuario lo cerró sin guardar).
  static Future<Map<String, dynamic>?> mostrar(
    BuildContext context, {
    required String nombres,
    required String apellidos,
    required String celular,
    required String avatarUrl,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EditProfileSheet(
        nombres: nombres,
        apellidos: apellidos,
        celular: celular,
        avatarUrl: avatarUrl,
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _celularCtrl;

  File? _nuevaFoto;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombresCtrl = TextEditingController(text: widget.nombres);
    _apellidosCtrl = TextEditingController(text: widget.apellidos);
    _celularCtrl = TextEditingController(text: celularDiezDigitos(widget.celular));
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _celularCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final XFile? elegida = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (elegida != null && mounted) {
      setState(() => _nuevaFoto = File(elegida.path));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'No se encontró tu sesión. Vuelve a iniciar sesión.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final r = await ApiService.actualizarPerfil(
      userId: userId,
      nombres: _nombresCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      celular: _celularCtrl.text.trim(),
      avatar: _nuevaFoto,
    );

    if (!mounted) return;

    if (r['success'] == true && r['usuario'] is Map) {
      Navigator.pop(context, Map<String, dynamic>.from(r['usuario'] as Map));
    } else {
      setState(() {
        _guardando = false;
        _error = r['message']?.toString() ?? 'No se pudo actualizar el perfil';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imagen;
    if (_nuevaFoto != null) {
      imagen = FileImage(_nuevaFoto!);
    } else if (widget.avatarUrl.isNotEmpty) {
      imagen = NetworkImage(widget.avatarUrl);
    }

    return Padding(
      // Sube el formulario cuando aparece el teclado
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('✏️ Editar perfil', style: AppTextStyles.h2),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: AvatarPicker(
                  imagen: imagen,
                  onTap: _guardando ? null : _elegirFoto,
                ),
              ),
              const SizedBox(height: 16),
              ProfileFormFields(
                nombresCtrl: _nombresCtrl,
                apellidosCtrl: _apellidosCtrl,
                celularCtrl: _celularCtrl,
                enabled: !_guardando,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              SaveButton(guardando: _guardando, onPressed: _guardar),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}