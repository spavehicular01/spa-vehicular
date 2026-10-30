import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/password_validator.dart';

class RegisterScreen extends StatefulWidget {
  /// Callback que actualiza la sesión de la app. Es opcional para no romper
  /// otros lugares que abran esta pantalla con `const RegisterScreen()`.
  final void Function(Map<String, dynamic> datos)? onLoginExitoso;

  const RegisterScreen({super.key, this.onLoginExitoso});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  final _confirmCorreoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Formato básico de correo: algo@dominio.ext
  static final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _confirmCorreoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Arma los datos de sesión. Si el registro no devolvió token o usuario,
  /// intenta iniciar sesión con las mismas credenciales.
  Future<Map<String, dynamic>?> _obtenerDatosSesion(
    Map resultado,
    String correo,
    String password,
  ) async {
    dynamic token = resultado['token'];
    dynamic usuario = resultado['usuario'];

    if (token == null || usuario == null) {
      final login = await AuthService.login(correo, password);
      final ok = login['ok'] == true || login['success'] == true;
      if (!ok) return null;
      token = login['token'];
      usuario = login['usuario'];
    }

    final Map u = usuario is Map ? usuario : {};

    return {
      'id': u['id'] ?? u['_id'] ?? '',
      'nombres': u['nombres'] ?? _nombresController.text.trim(),
      'apellidos': u['apellidos'] ?? _apellidosController.text.trim(),
      'correo': u['correo'] ?? u['email'] ?? correo,
      'rol': u['rol'] ?? 'cliente',
      'documento': u['documentoIdentidad'] ??
          u['documento'] ??
          _documentoController.text.trim(),
      'telefono': u['celular'] ?? u['telefono'] ?? _telefonoController.text.trim(),
      'vehiculos': u['vehiculos'] ?? [],
      'token': token,
      'citas': [],
      'historial': [],
    };
  }

  // Procesa el registro consumiendo AuthService
  Future<void> _procesarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final correo = _correoController.text.trim();
    final password = _passwordController.text;

    final resultado = await AuthService.registrar(
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      documentoIdentidad: _documentoController.text.trim(),
      correo: correo,
      celular: _telefonoController.text.trim(),
      password: password,
    );

    if (!mounted) return;

    if (resultado['success'] != true) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Error al registrar usuario.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (resultado['token'] != null) {
      await prefs.setString('token', resultado['token']);
    }
    await prefs.setString('user_email', correo);

    if (!mounted) return;

    // Requiere verificar el correo antes de entrar
    if (resultado['requireVerification'] == true) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? '¡Registro exitoso! Verifica tu correo.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(
        context,
        '/verificar-codigo',
        arguments: correo,
      );
      return;
    }

    // Registro completo: se inicia la sesión en la app
    final callback = widget.onLoginExitoso;
    if (callback == null) {
      // Compatibilidad con quien abra esta pantalla sin callback
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? '¡Registro exitoso! Bienvenido.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      return;
    }

    final datos = await _obtenerDatosSesion(resultado, correo, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (datos != null) {
      callback(datos);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? '¡Registro exitoso! Bienvenido.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Inicia sesión para continuar.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Vuelve a la pantalla principal (ya con la sesión iniciada)
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Ingresa tus nombres' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Ingresa tus apellidos' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (val) {
                  final correo = val?.trim() ?? '';
                  if (!_formatoCorreo.hasMatch(correo)) return 'Ingresa un correo válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // El código de verificación se envía a este correo: si tiene un
              // error de escritura, el correo rebota y la cuenta no se puede activar.
              TextFormField(
                controller: _confirmCorreoController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Confirmar correo electrónico',
                  prefixIcon: Icon(Icons.mark_email_read_outlined),
                ),
                validator: (val) {
                  final confirmacion = (val ?? '').trim().toLowerCase();
                  final correo = _correoController.text.trim().toLowerCase();
                  if (confirmacion.isEmpty) return 'Confirma tu correo';
                  if (confirmacion != correo) return 'Los correos no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _documentoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Documento de Identidad',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Ingresa tu documento' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (val) => val == null || val.trim().length < 7
                    ? 'Ingresa un teléfono válido'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                // Refresca el checklist de requisitos mientras se escribe
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: PasswordValidator.validar,
              ),
              PasswordChecklist(password: _passwordController.text),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _procesarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brand,
                  foregroundColor: context.onBrand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: context.onBrand,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}