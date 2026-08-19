import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_navigation_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}