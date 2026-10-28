import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_config.dart';

/// Conexión en tiempo real con el servidor. El servidor exige el token JWT,
/// y cada usuario recibe solo sus propios avisos.
class SocketService {
  IO.Socket? _socket;
  bool _cerrado = false;

  /// [onCambioEstado]: cambios de estado de las citas (pasar null si no interesa).
  /// [onNuevaNotificacion]: llega cuando se guarda una notificación nueva del usuario.
  Future<void> conectar(
    Function(dynamic)? onCambioEstado, {
    Function(dynamic)? onNuevaNotificacion,
  }) async {
    _cerrado = false;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Sin sesión no hay conexión; y si mientras tanto se pidió desconectar, tampoco.
    if (token.isEmpty || _cerrado) return;

    _socket?.dispose();
    _socket = IO.io(
      ApiConfig.baseUrl.replaceAll('/api', ''),
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    if (onCambioEstado != null) {
      _socket?.on('cambio_estado_cita', (data) => onCambioEstado(data));
    }
    if (onNuevaNotificacion != null) {
      _socket?.on('nueva_notificacion', (data) => onNuevaNotificacion(data));
    }
  }

  void desconectar() {
    _cerrado = true;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}