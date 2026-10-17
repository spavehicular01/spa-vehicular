import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'session_guard.dart';

/// Notificaciones push (como las de Facebook): el servidor envía el aviso al celular
/// aunque la app esté cerrada. Si Firebase no está configurado, la app funciona igual,
/// solo sin push.
class PushService {
  // Debe coincidir con el canal que usa el servidor y con AndroidManifest.xml
  static const String _canalId = 'notificaciones_spa';
  static const String _canalNombre = 'Avisos del spa';

  static final FlutterLocalNotificationsPlugin _locales = FlutterLocalNotificationsPlugin();
  static bool _disponible = false;

  // Evita registrar varias veces el mismo celular con la misma sesión
  static String? _ultimoRegistro;

  /// Se llama una vez al abrir la app.
  static Future<void> iniciar() async {
    try {
      await Firebase.initializeApp();
      _disponible = true;
    } catch (e) {
      debugPrint('Push desactivado: Firebase no está configurado ($e)');
      return;
    }

    try {
      // Android 13 o superior: pide permiso para mostrar notificaciones
      await FirebaseMessaging.instance.requestPermission();

      await _locales.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        ),
      );

      // Canal de importancia alta: el aviso aparece como banner sobre la pantalla
      await _locales
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _canalId,
              _canalNombre,
              description: 'Avisos de tus citas, del estado de tu vehículo y de pagos',
              importance: Importance.high,
            ),
          );

      // Con la app abierta, Firebase no muestra el aviso solo: se muestra aquí
      FirebaseMessaging.onMessage.listen(_mostrarEnPrimerPlano);

      // Si Firebase cambia el identificador del celular, se vuelve a registrar
      FirebaseMessaging.instance.onTokenRefresh.listen((nuevo) {
        registrarDispositivo(tokenFcm: nuevo);
      });
    } catch (e) {
      debugPrint('Error al preparar las notificaciones push: $e');
    }
  }

  static Future<void> _mostrarEnPrimerPlano(RemoteMessage mensaje) async {
    final notificacion = mensaje.notification;
    if (notificacion == null) return;

    await _locales.show(
      id: notificacion.hashCode,
      title: notificacion.title,
      body: notificacion.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNombre,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Le dice al servidor a qué celular enviar los avisos de la sesión actual.
  /// Se llama al iniciar sesión y al abrir la app con la sesión guardada.
  static Future<void> registrarDispositivo({String? tokenFcm}) async {
    if (!_disponible) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('token') ?? '';
      if (jwt.isEmpty) return;

      final fcm = tokenFcm ?? await FirebaseMessaging.instance.getToken();
      if (fcm == null || fcm.isEmpty) return;

      final clave = '$jwt|$fcm';
      if (clave == _ultimoRegistro) return;

      final response = SessionGuard.revisar(await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'token': fcm,
              'plataforma': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            }),
          )
          .timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200) {
        _ultimoRegistro = clave;
      } else {
        debugPrint('No se pudo registrar el celular para push (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error al registrar el celular para push: $e');
    }
  }

  /// Quita el celular de la cuenta al cerrar sesión, para que deje de recibir sus avisos.
  /// Debe llamarse ANTES de borrar el token de sesión.
  static Future<void> quitarDispositivo() async {
    if (!_disponible) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('token') ?? '';
      final fcm = await FirebaseMessaging.instance.getToken();
      _ultimoRegistro = null;

      if (jwt.isEmpty || fcm == null || fcm.isEmpty) return;

      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices/baja'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({'token': fcm}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error al quitar el celular de push: $e');
    }
  }
}