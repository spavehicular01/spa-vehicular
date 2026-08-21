import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;

  void conectar(Function(Map<String, dynamic>) onCambioEstado) {
    // 10.0.2.2 para emulador Android, o la IP local de tu máquina para celular físico
    _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print('Conectado al servidor WebSocket');
    });

    // Escuchar el evento emitido desde el backend
    _socket.on('cambio_estado_cita', (data) {
      if (data != null) {
        onCambioEstado(Map<String, dynamic>.from(data));
      }
    });

    _socket.onDisconnect((_) => print('Desconectado de WebSocket'));
  }

  void desconectar() {
    _socket.disconnect();
  }
}