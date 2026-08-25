import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_navigation_screen.dart';

// Definición del azul eléctrico exacto
const Color azulPrincipal = Color(0xFF0004FF);

void main() {
  runApp(const SpaVehicularApp());
}

class SpaVehicularApp extends StatelessWidget {
  const SpaVehicularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spa Vehicular',
      
      // Configuración regional para Colombia / Español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'), // Español Colombia
      ],
      locale: const Locale('es', 'CO'),

      theme: ThemeData(
        useMaterial3: true,
        primaryColor: azulPrincipal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azulPrincipal,
          primary: azulPrincipal,
        ),
        // Estilo global para las barras superiores
        appBarTheme: const AppBarTheme(
          backgroundColor: azulPrincipal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // Estilo global para los botones principales
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: azulPrincipal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // Estilo global para los botones flotantes (FAB)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: azulPrincipal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}