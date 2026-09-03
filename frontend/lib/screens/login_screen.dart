import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Map<String, dynamic>? _registeredUserData;

  // Credenciales oficiales del Administrador (SPA)
  static const String _adminEmail = 'spavehicular01@gmail.com';
  static const String _adminPassword = 'spa_veh_01';

  // Usuarios cliente simulados
  final List<String> _usuariosValidos = [
    'diegobeltran0207@gmail.com',
    'admin@carwash.com',
    'didiercediel58@gmail.com',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

    // 1. VALIDACIÓN PARA EL ADMINISTRADOR
    if (email == _adminEmail) {
      if (password != _adminPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña de administrador incorrecta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'token_auth_valido_12345');
      await prefs.setString('user_email', email);

      widget.onLoginExitoso({
        'nombres': 'Administrador SPA',
        'correo': email,
        'rol': 'admin',
        'documento': '0000000000',
        'telefono': '3000000000',
        'vehiculos': [],
        'citas': [],
        'historial': [],
      });
      return;
    }

    // 2. VALIDACIÓN PARA CLIENTES
    final bool existe = _usuariosValidos.contains(email) ||
        (_registeredUserData != null && _registeredUserData!['correo'] == email);

    if (!existe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este usuario no existe. Por favor regístrate.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Guarda la sesión localmente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'token_auth_valido_12345');
    await prefs.setString('user_email', email);

    widget.onLoginExitoso({
      'nombres': _registeredUserData?['nombres'] ?? 'Usuario',
      'correo': email,
      'rol': 'cliente',
      'documento': _registeredUserData?['documento'] ?? '1077856793',
      'telefono': _registeredUserData?['telefono'] ?? '3202819751',
      'vehiculos': _registeredUserData?['vehiculos'] ?? [],
      'citas': [],
      'historial': [],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Color(0xFF001EFF)),
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
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              
              // Enlace: Restablecer Contraseña
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
                  child: const Text(
                    '¿Has olvidado tu contraseña?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0011FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              
              // 🚀 BOTÓN REGISTRARSE: REDIRIGE DIRECTO TRAS REGISTRO
              OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );

                  // Si el registro retorna los datos del usuario, ingresa de inmediato a la App
                  if (result != null && result is Map<String, dynamic>) {
                    widget.onLoginExitoso(result);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0026FF),
                  side: const BorderSide(color: Color(0xFF001AFF), width: 1.5),
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