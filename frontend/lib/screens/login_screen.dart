import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_reset_code_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLoginExitoso;

  const LoginScreen({
    super.key,
    required this.onLoginExitoso,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _cargando = false;
  bool _cargandoGoogle = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Avisa a la app de la sesión y vuelve a la pantalla principal.
  /// Si esta pantalla va embebida en la pestaña Perfil, popUntil no hace nada
  /// y el cambio de sesión actualiza la vista por sí solo.
  void _completarLogin(Map<String, dynamic> datos) {
    widget.onLoginExitoso(datos);
    if (!mounted) return;
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  Map<String, dynamic> _armarDatos(Map usuario, dynamic token, String correoRespaldo) {
    return {
      'id': usuario['id'] ?? usuario['_id'] ?? '',
      'nombres': usuario['nombres'] ?? usuario['Nombre'] ?? 'Usuario',
      'apellidos': usuario['apellidos'] ?? usuario['Apellido'] ?? '',
      'correo': usuario['correo'] ??
          usuario['email'] ??
          usuario['Correo_Electronico'] ??
          correoRespaldo,
      'rol': usuario['rol'] ?? 'cliente',
      'documento': usuario['documentoIdentidad'] ?? usuario['documento'] ?? '',
      'telefono': usuario['celular'] ?? usuario['telefono'] ?? '',
      'vehiculos': usuario['vehiculos'] ?? [],
      'token': token,
      'citas': [],
      'historial': [],
    };
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa correo y contraseña'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    final resultado = await AuthService.login(email, password);

    if (!mounted) return;
    setState(() => _cargando = false);

    final esExitoso = resultado['ok'] == true || resultado['success'] == true;

    if (esExitoso) {
      final usuario = resultado['usuario'] ?? {};
      _completarLogin(_armarDatos(usuario, resultado['token'], email));
    } else if (resultado['requiereVerificacion'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyResetCodeScreen(
            email: resultado['email'] ?? email,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['mensaje'] ?? resultado['message'] ?? 'Error al iniciar sesión',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Login con Google
  Future<void> _iniciarSesionConGoogle() async {
    setState(() => _cargandoGoogle = true);

    final resultado = await AuthService.loginConGoogle();

    if (!mounted) return;
    setState(() => _cargandoGoogle = false);

    if (resultado['success'] == true) {
      final usuario = resultado['usuario'] ?? {};
      _completarLogin(_armarDatos(usuario, resultado['token'], ''));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Error al iniciar sesión con Google'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // Si se abrió desde el diálogo (hay pantalla detrás), se muestra la flecha de volver.
      appBar: Navigator.of(context).canPop() ? AppBar(title: const Text('Iniciar sesión')) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.person, size: 46, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bienvenido',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '¿Has olvidado tu contraseña?',
                    style: TextStyle(
                      color: context.brandText,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _cargando ? null : _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brand,
                  foregroundColor: context.onBrand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _cargando
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: context.onBrand,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Separador visual
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('o', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Botón de Google
              OutlinedButton.icon(
                onPressed: _cargandoGoogle ? null : _iniciarSesionConGoogle,
                icon: _cargandoGoogle
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.network(
                        'https://www.google.com/favicon.ico',
                        height: 20,
                        width: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.login, size: 20),
                      ),
                label: const Text(
                  'Continuar con Google',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(
                    color: context.isDark ? AppColors.darkBorder : Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              OutlinedButton(
                onPressed: () {
                  // RegisterScreen avisa a la app y vuelve a la pantalla principal por sí sola.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(
                        onLoginExitoso: widget.onLoginExitoso,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.brandText,
                  side: BorderSide(color: context.brandText, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
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