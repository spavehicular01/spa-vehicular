import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // guardarSesionUsuario
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String? email;

  /// false (por defecto): verifica una cuenta nueva con el código del registro.
  /// true: restablece la contraseña con el código de "¿Olvidaste tu contraseña?".
  final bool esRecuperacion;

  const VerifyResetCodeScreen({
    super.key,
    this.email,
    this.esRecuperacion = false,
  });

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _ocultarPassword = true;

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
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Valida el código; devuelve true si está bien.
  bool _codigoValido(String code) {
    if (_emailFinal.isEmpty) {
      _showSnackBar('El correo no es válido. Intenta ingresar de nuevo.', Colors.red);
      return false;
    }
    if (code.isEmpty) {
      _showSnackBar('Por favor, ingresa el código', Colors.red);
      return false;
    }
    if (code.length != 6) {
      _showSnackBar('El código debe tener 6 dígitos', Colors.red);
      return false;
    }
    return true;
  }

  /// Datos de sesión con el mismo formato que usa la pantalla de inicio de sesión.
  Map<String, dynamic> _armarDatosSesion(Map usuario, dynamic token) {
    return {
      'id': usuario['id'] ?? usuario['_id'] ?? '',
      'nombres': usuario['nombres'] ?? usuario['Nombre'] ?? 'Usuario',
      'apellidos': usuario['apellidos'] ?? usuario['Apellido'] ?? '',
      'correo': usuario['correo'] ??
          usuario['email'] ??
          usuario['Correo_Electronico'] ??
          _emailFinal,
      'rol': usuario['rol'] ?? 'cliente',
      'documento': usuario['documentoIdentidad'] ?? usuario['documento'] ?? '',
      'telefono': usuario['celular'] ?? usuario['telefono'] ?? '',
      'vehiculos': usuario['vehiculos'] ?? [],
      'token': token,
      'citas': [],
      'historial': [],
    };
  }

  // Modo 1: verificar cuenta nueva (registro)
  Future<void> _verificarCodigo() async {
    final code = _codeController.text.trim();
    if (!_codigoValido(code)) return;

    setState(() => _isLoading = true);

    final resultado = await AuthService.verificarCuenta(
      email: _emailFinal,
      codigo: code,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['success'] != true) {
      _showSnackBar(resultado['message'] ?? 'Error al verificar el código', Colors.red);
      return;
    }

    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', _emailFinal);

    final token = resultado['token'];
    final usuario = resultado['usuario'];

    if (token != null && usuario is Map) {
      // Cuenta verificada: se inicia la sesión sola, sin pedir de nuevo correo y contraseña
      await guardarSesionUsuario(_armarDatosSesion(usuario, token));

      if (!mounted) return;
      _showSnackBar('Cuenta verificada correctamente. ¡Bienvenido!', Colors.green);
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      // Respaldo: la cuenta quedó verificada pero el servidor no devolvió la sesión
      if (!mounted) return;
      _showSnackBar('Cuenta verificada. Ahora inicia sesión.', Colors.green);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Modo 2: restablecer contraseña (¿Olvidaste tu contraseña?)
  Future<void> _restablecerPassword() async {
    final code = _codeController.text.trim();
    final nueva = _passwordController.text;
    final confirmar = _confirmController.text;

    if (!_codigoValido(code)) return;

    if (nueva.length < 6) {
      _showSnackBar('La nueva contraseña debe tener mínimo 6 caracteres', Colors.red);
      return;
    }
    if (nueva != confirmar) {
      _showSnackBar('Las contraseñas no coinciden', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.restablecerPassword(
      email: _emailFinal,
      codigo: code,
      nuevaPassword: nueva,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['success'] == true) {
      _timer?.cancel();

      _showSnackBar(
        resultado['message'] ?? 'Contraseña actualizada. Ya puedes iniciar sesión.',
        Colors.green,
      );

      // Vuelve a la pantalla principal, donde está el inicio de sesión
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } else {
      _showSnackBar(resultado['message'] ?? 'No se pudo cambiar la contraseña', Colors.red);
    }
  }

  Future<void> _reenviarCodigo() async {
    if (_emailFinal.isEmpty) {
      _showSnackBar('No se encontró el correo del usuario.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    // Cada modo tiene su propio código: se reenvía el que corresponde
    final resultado = widget.esRecuperacion
        ? await AuthService.solicitarCodigoRecuperacion(_emailFinal)
        : await AuthService.reenviarCodigo(email: _emailFinal);

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool recuperacion = widget.esRecuperacion;

    return Scaffold(
      appBar: AppBar(
        title: Text(recuperacion ? 'Restablecer Contraseña' : 'Verificar Cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                recuperacion ? Icons.lock_reset : Icons.mark_email_read_outlined,
                size: 80,
                color: context.brandText,
              ),
              const SizedBox(height: 16),
              Text(
                recuperacion ? 'Crea tu nueva contraseña' : 'Ingresa el Código de Verificación',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

              // Solo en el modo de recuperación: contraseña nueva
              if (recuperacion) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmController,
                  obscureText: _ocultarPassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              Text(
                _secondsRemaining > 0
                    ? 'El código expira en: $_formattedTime'
                    : 'El código ha expirado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondsRemaining > 0 ? (isDark ? Colors.white70 : Colors.black87) : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (recuperacion ? _restablecerPassword : _verificarCodigo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brand,
                  foregroundColor: context.onBrand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                    : Text(
                        recuperacion ? 'Cambiar contraseña' : 'Verificar y Entrar',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: (_canResend && !_isLoading) ? _reenviarCodigo : null,
                child: Text(
                  _canResend
                      ? '¿No recibiste el código? Reenviar'
                      : 'Puedes reenviar en $_formattedTime',
                  style: TextStyle(
                    color: _canResend ? context.brandText : Colors.grey,
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