import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Base de datos simulada en memoria para validar duplicados
  static final List<String> _documentosRegistrados = ['123456789', '1010203040'];

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _procesarRegistro() {
    if (_formKey.currentState!.validate()) {
      final doc = _documentoController.text.trim();

      // Validar si el número de documento ya existe
      if (_documentosRegistrados.contains(doc)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ El número de documento ya se encuentra registrado.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Registrar documento para evitar futuros duplicados
      _documentosRegistrados.add(doc);

      // Simulación de correo enviado "Bienvenido al SPA VEHICULAR"
      _mostrarDialogoConfirmacionCorreo();
    }
  }

  void _mostrarDialogoConfirmacionCorreo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('📧 Correo de Verificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hemos enviado un correo a:\n${_correoController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                ' Asunto: Bienvenido al SPA VEHICULAR\n\n'
                'Gracias por unirte. Presiona el botón a continuación para verificar tu cuenta e iniciar sesión.',
                style: TextStyle(fontSize: 13, color: Color.fromARGB(255, 0, 34, 252)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 0, 34, 255)),
            onPressed: () {
              Navigator.pop(ctx); // Cierra modal
              Navigator.pop(context, {
                'nombres': '${_nombresController.text} ${_apellidosController.text}',
                'correo': _correoController.text,
                'documento': _documentoController.text,
                'telefono': _telefonoController.text,
              }); // Retorna datos de usuario al Login/App
            },
            child: const Text('Confirmar Cuenta', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: const Color.fromARGB(255, 0, 26, 255),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombres
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Ingresa tus nombres' : null,
              ),
              const SizedBox(height: 16),

              // Apellidos
              TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Ingresa tus apellidos' : null,
              ),
              const SizedBox(height: 16),

              // Correo
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || !val.contains('@')) return 'Ingresa un correo válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Documento de Identidad
              TextFormField(
                controller: _documentoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Documento de Identidad',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Ingresa tu documento' : null,
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de Teléfono',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.length < 7 ? 'Ingresa un teléfono válido' : null,
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),

              // Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                onPressed: _procesarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 30, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Registrarse', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}