import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/register_screen.dart';

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

  // Usuarios simulados base
  final List<String> _usuariosValidos = ['diegobeltran0207@gmail.com', 'admin@carwash.com', 'didiercediel58@gmail.com'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa correo y contraseña'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validar si el correo existe en registro reciente o usuarios base
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

    // Guarda la sesión localmente para que ServicesScreen detecte la autenticación
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'token_auth_valido_12345');
    await prefs.setString('user_email', email);

    widget.onLoginExitoso({
      'nombres': _registeredUserData?['nombres'] ?? 'Didier Cediel',
      'correo': email,
      'documento': _registeredUserData?['documento'] ?? '1077856793',
      'telefono': _registeredUserData?['telefono'] ?? '3202819751',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.teal),
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
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    // Si viene de un registro exitoso, también guardamos el token
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('token', 'token_auth_valido_12345');

                    setState(() {
                      _registeredUserData = result;
                      _emailController.text = result['correo'] ?? '';
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Registrarse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}