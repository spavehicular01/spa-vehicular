import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'profile/edit_profile_sheet.dart';
import 'profile/phone_card.dart';
import 'profile/profile_header.dart';
import 'profile/profile_utils.dart';
import 'profile/vehicles_section.dart';

class ProfileScreen extends StatefulWidget {
  final String nombreCompleto;
  final String correo;
  final String documento;
  final String telefono;
  final List<Map<String, String>> vehiculos;
  final Function(List<Map<String, String>>) onVehiculosChanged;
  final VoidCallback onCerrarSesion;

  // Opcionales: si el padre los envía, el formulario los usa tal cual.
  // Si no, se separan a partir de nombreCompleto.
  final String nombres;
  final String apellidos;
  final String avatarUrl;

  // Opcional: se llama cuando el backend confirma el cambio de perfil.
  final void Function(Map<String, dynamic> usuario)? onPerfilActualizado;

  const ProfileScreen({
    super.key,
    required this.nombreCompleto,
    required this.correo,
    required this.documento,
    required this.telefono,
    required this.vehiculos,
    required this.onVehiculosChanged,
    required this.onCerrarSesion,
    this.nombres = '',
    this.apellidos = '',
    this.avatarUrl = '',
    this.onPerfilActualizado,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Copia local de los datos editables, para refrescar la pantalla al guardar
  late String _nombres;
  late String _apellidos;
  late String _nombreCompleto;
  late String _telefono;
  late String _avatarUrl;

  @override
  void initState() {
    super.initState();
    _sincronizarDatosPerfil();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo se vuelve a copiar si el padre mandó datos distintos a los anteriores
    if (oldWidget.nombreCompleto != widget.nombreCompleto ||
        oldWidget.nombres != widget.nombres ||
        oldWidget.apellidos != widget.apellidos ||
        oldWidget.telefono != widget.telefono ||
        oldWidget.avatarUrl != widget.avatarUrl) {
      setState(_sincronizarDatosPerfil);
    }
  }

  void _sincronizarDatosPerfil() {
    final separado = separarNombre(widget.nombreCompleto);
    _nombres = widget.nombres.isNotEmpty ? widget.nombres : separado[0];
    _apellidos = widget.apellidos.isNotEmpty ? widget.apellidos : separado[1];
    _nombreCompleto = widget.nombreCompleto;
    _telefono = widget.telefono;
    _avatarUrl = widget.avatarUrl;
  }

  Future<void> _ejecutarCerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    widget.onCerrarSesion();
  }

  Future<void> _abrirEditarPerfil() async {
    final result = await EditProfileSheet.mostrar(
      context,
      nombres: _nombres,
      apellidos: _apellidos,
      celular: _telefono,
      avatarUrl: _avatarUrl,
    );
    if (result == null || !mounted) return;

    setState(() {
      _nombres = result['nombres']?.toString() ?? _nombres;
      _apellidos = result['apellidos']?.toString() ?? _apellidos;
      _nombreCompleto = '$_nombres $_apellidos'.trim();
      _telefono = result['celular']?.toString() ?? _telefono;
      _avatarUrl = result['avatar']?.toString() ?? _avatarUrl;
    });

    widget.onPerfilActualizado?.call(result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          ProfileHeader(
            avatarUrl: _avatarUrl,
            nombreCompleto: _nombreCompleto,
            correo: widget.correo,
            onEditar: _abrirEditarPerfil,
          ),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.badge, color: AppColors.secondary),
            title: const Text('Documento de Identidad'),
            subtitle: Text(widget.documento),
          ),
          PhoneCard(telefono: _telefono),
          VehiclesSection(
            vehiculosIniciales: widget.vehiculos,
            onVehiculosChanged: widget.onVehiculosChanged,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _ejecutarCerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }
}