import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation_screen.dart';

// Definición del azul eléctrico exacto
const Color azulPrincipal = Color(0xFF0004FF);

// Notificadores globales de estado
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<double> fontSizeNotifier = ValueNotifier(1.0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar preferencias guardadas antes de iniciar la app
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('modo_oscuro') ?? false;
  final fontScale = prefs.getDouble('font_scale') ?? 1.0;

  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  fontSizeNotifier.value = fontScale;

  runApp(const SpaVehicularApp());
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
              title: 'SPA VEHICULAR',

              // Configuración de temas global (Modo Claro / Oscuro)
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

              // Configuración regional para Colombia / Español
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('es', 'CO'),
              ],
              locale: const Locale('es', 'CO'),

              // Escala global del tamaño de texto en toda la app
              builder: (context, child) {
                final mediaQueryData = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQueryData.copyWith(
                    textScaler: TextScaler.linear(fontScale),
                  ),
                  child: child!,
                );
              },

              home: const MainNavigationScreen(),
            );
          },
        );
      },
    );
  }
}