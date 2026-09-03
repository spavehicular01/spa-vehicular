import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String? email;

  const VerifyResetCodeScreen({
    super.key,
    this.email,
  });

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  // Correo recuperado e inmutable para las peticiones API
  String _emailFinal = '';

  // Temporizador de 10 minutos (600 segundos)
  int _secondsRemaining = 600;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Captura el email desde el widget o desde los argumentos de ruta
    if (_emailFinal.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (widget.email != null && widget.email!.trim().isNotEmpty) {
        _emailFinal = widget.email!.trim();
      } else if (args is String && args.trim().isNotEmpty) {
        _emailFinal = args.trim();
      }
    }
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 600;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (mounted) setState(() => _canResend = true);
      }
    });
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verificarCodigo() async {
    final code = _codeController.text.trim();

    if (_emailFinal.isEmpty) {
      _showSnackBar('El correo no es válido. Intenta ingresar de nuevo.', Colors.red);
      return;
    }

    if (code.isEmpty) {
      _showSnackBar('Por favor, ingresa el código', Colors.red);
      return;
    }

    if (code.length != 6) {
      _showSnackBar('El código debe tener 6 dígitos', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.verificarCuenta(
      email: _emailFinal,
      codigo: code,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['success'] == true) {
      _timer?.cancel();

      // Guardar persistencia de la sesión en el dispositivo
      final prefs = await SharedPreferences.getInstance();
      if (resultado['token'] != null) {
        await prefs.setString('token', resultado['token']);
      } else {
        await prefs.setString('token', 'token_verificado_exitoso');
      }
      await prefs.setString('user_email', _emailFinal);

      if (!mounted) return;
      _showSnackBar(resultado['message'] ?? 'Cuenta verificada correctamente. ¡Bienvenido!', Colors.green);

      // 🚀 REDIRECCIÓN DIRECTA A LA PANTALLA PRINCIPAL
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/', // Ruta principal
        (route) => false,
      );
    } else {
      _showSnackBar(resultado['message'] ?? 'Error al verificar el código', Colors.red);
    }
  }

  Future<void> _reenviarCodigo() async {
    if (_emailFinal.isEmpty) {
      _showSnackBar('No se encontró el correo del usuario.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.reenviarCodigo(email: _emailFinal);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['success'] == true) {
      _showSnackBar('Nuevo código enviado a tu correo', Colors.green);
      _startTimer();
    } else {
      _showSnackBar(resultado['message'] ?? 'Error al reenviar el código', Colors.red);
    }
  }

  void _showSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Cuenta'),
        backgroundColor: const Color(0xFF001EFF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: Color(0xFF001EFF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ingresa el Código de Verificación',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _emailFinal.isNotEmpty
                    ? 'Enviamos un código de 6 dígitos a:\n$_emailFinal'
                    : 'Enviamos un código de 6 dígitos a tu correo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Tiempo de expiración
              Text(
                _secondsRemaining > 0
                    ? 'El código expira en: $_formattedTime'
                    : 'El código ha expirado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondsRemaining > 0 ? Colors.black87 : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Botón de Verificación
              ElevatedButton(
                onPressed: _isLoading ? null : _verificarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0011FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verificar y Entrar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 12),

              // Botón Reenviar
              TextButton(
                onPressed: (_canResend && !_isLoading) ? _reenviarCodigo : null,
                child: Text(
                  _canResend
                      ? '¿No recibiste el código? Reenviar'
                      : 'Puedes reenviar en $_formattedTime',
                  style: TextStyle(
                    color: _canResend ? const Color(0xFF0011FF) : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}