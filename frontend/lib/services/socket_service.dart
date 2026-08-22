import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_config.dart';

class SocketService {
  IO.Socket? _socket;

  void conectar(Function(dynamic) onCambioEstado) {
    _socket = IO.io(
      ApiConfig.baseUrl.replaceAll('/api', ''),
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.on('cambio_estado_cita', (data) {
      onCambioEstado(data);
    });
  }

  void desconectar() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}