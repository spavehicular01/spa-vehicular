import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_navigation_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verify_reset_code_screen.dart';
// Import del chat

// Definición del azul eléctrico
const Color azulPrincipal = Color(0xFF0004FF);

// Notificadores globales de estado
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<double> fontSizeNotifier = ValueNotifier(1.0);

// 🟢 NUEVO: Notificador global del usuario autenticado.
// Cualquier pantalla puede leer usuarioActualNotifier.value para
// obtener el usuario actual (o null si no hay sesión).
final ValueNotifier<Map<String, dynamic>?> usuarioActualNotifier =
    ValueNotifier(null);

// 🟢 NUEVO: Observador global de rutas, para que las pantallas puedan
// enterarse cuando vuelven a quedar visibles (ej. al volver de agendar).
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar preferencias guardadas antes de iniciar la app
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('modo_oscuro') ?? false;
  final fontScale = prefs.getDouble('font_scale') ?? 1.0;

  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  fontSizeNotifier.value = fontScale;

  // 🟢 NUEVO: Recuperar sesión de usuario guardada (si existe),
  // para que sobreviva a un reinicio de la app.
  final usuarioGuardadoStr = prefs.getString('usuario');
  if (usuarioGuardadoStr != null && usuarioGuardadoStr.isNotEmpty) {
    try {
      usuarioActualNotifier.value =
          jsonDecode(usuarioGuardadoStr) as Map<String, dynamic>;
    } catch (_) {
      // Si el JSON guardado está corrupto, se ignora y se sigue sin sesión.
      usuarioActualNotifier.value = null;
    }
  }

  runApp(const SpaVehicularApp());
}

// 🟢 NUEVO: Helper reutilizable para guardar la sesión completa
// (usuario en memoria + disco). Úsalo en cualquier parte donde el
// login sea exitoso (login normal o registro con login automático).
//
// 🔧 CORREGIDO: además de guardar el objeto 'usuario' completo como JSON,
// ahora también guarda 'userId' y 'token' como claves sueltas en
// SharedPreferences, que es lo que esperan AddVehicleScreen y
// WashApiService al leer la sesión.
Future<void> guardarSesionUsuario(Map<String, dynamic> userData) async {
  usuarioActualNotifier.value = userData;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('usuario', jsonEncode(userData));

  final userId =
      userData['id']?.toString() ?? userData['_id']?.toString() ?? '';
  final token = userData['token']?.toString() ?? '';

  if (userId.isNotEmpty) {
    await prefs.setString('userId', userId);
  }
  if (token.isNotEmpty) {
    await prefs.setString('token', token);
  }
}

// 🟢 NUEVO: Helper para cerrar sesión limpiamente desde cualquier pantalla.
// 🔧 CORREGIDO: ahora también elimina 'userId' al cerrar sesión.
Future<void> cerrarSesionUsuario() async {
  usuarioActualNotifier.value = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('usuario');
  await prefs.remove('token');
  await prefs.remove('userId');
}

class SpaVehicularApp extends StatelessWidget {
  const SpaVehicularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return ValueListenableBuilder<double>(
          valueListenable: fontSizeNotifier,
          builder: (_, fontScale, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Spa Vehicular',
              navigatorObservers: [routeObserver], // 🟢 NUEVO

              // Configuración de temas global
              themeMode: currentMode,

              // Tema Claro
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                primaryColor: azulPrincipal,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: azulPrincipal,
                  primary: azulPrincipal,
                  brightness: Brightness.light,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                ),
              ),

              // Tema Oscuro
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                primaryColor: azulPrincipal,
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: azulPrincipal,
                  primary: azulPrincipal,
                  brightness: Brightness.dark,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                ),
              ),

              // Localización (Colombia / Español)
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('es', 'CO'),
              ],
              locale: const Locale('es', 'CO'),

              // Escala de texto
              builder: (context, child) {
                final mediaQueryData = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQueryData.copyWith(
                    textScaler: TextScaler.linear(fontScale),
                  ),
                  child: child!,
                );
              },

              // Pantalla inicial
              initialRoute: '/',

              // Manejo unificado de rutas con soporte para argumentos
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/':
                    return MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                      settings: settings,
                    );

                  case '/login':
                    return MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        onLoginExitoso: (userData) async {
                          // 🟢 CAMBIO CLAVE: ahora sí guardamos el usuario
                          // en memoria y en disco antes de navegar.
                          await guardarSesionUsuario(userData);

                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                      ),
                      settings: settings,
                    );

                  case '/registro':
                    return MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                      settings: settings,
                    );

                  case '/verificar-codigo':
                  case '/verificar-codigo-restablecer':
                    final emailArg = settings.arguments as String?;
                    return MaterialPageRoute(
                      builder: (context) => VerifyResetCodeScreen(
                        email: emailArg ?? '',
                      ),
                      settings: settings,
                    );

                  default:
                    return MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                      settings: settings,
                    );
                }
              },
            );
          },
        );
      },
    );
  }
}