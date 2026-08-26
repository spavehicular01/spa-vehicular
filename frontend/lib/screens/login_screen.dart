import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart'; // Import de la pantalla de recuperación

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
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
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

    // 1. VALIDACIÓN PARA EL ADMINISTRADOR (spavehicular01@gmail.com)
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

      // Entra como ADMINISTRADOR con datos por defecto completos
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

    // 2. VALIDACIÓN PARA CLIENTES (Diego y registrados)
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

    // Entra como CLIENTE
    widget.onLoginExitoso({
      'nombres': _registeredUserData?['nombres'] ?? 'Diego Beltrán',
      'correo': email,
      'rol': 'cliente',
      'documento': _registeredUserData?['documento'] ?? '1077852343',
      'telefono': _registeredUserData?['telefono'] ?? '3102581864',
      'vehiculos': _registeredUserData?['vehiculos'] ?? [
        {'placa': 'ABC123', 'marca': 'Toyota', 'referencia': 'Hilux', 'modelo': '2022', 'color': 'Blanco'}
      ],
      'citas': [
        {'fecha': '2026-08-25', 'hora': '10:00 AM', 'servicio': 'Lavado General'},
      ],
      'historial': [
        {'fecha': '2026-08-10', 'servicio': 'Polichado', 'monto': '\$45.000'},
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.account_circle, size: 80, color: Color.fromARGB(255, 0, 30, 255)),
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
          
          // --- ENLACE AGREGADO: RESTABLECER CONTRASEÑA ---
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
          // ----------------------------------------------

          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _iniciarSesion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 17, 255),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  _registeredUserData = result;
                  _emailController.text = result['correo'] ?? '';
                });
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 0, 38, 255),
              side: const BorderSide(color: Color.fromARGB(255, 0, 26, 255), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Registrarse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}