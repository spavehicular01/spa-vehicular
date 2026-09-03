import 'package:flutter/material.dart';

class AppTheme {
  // Azul puro exacto de tu imagen: #0033FF
  static const Color azulElectrico = Color(0xFF0033FF);
  static const Color azulOscuro = Color(0xFF0022FF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: azulElectrico,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: ColorScheme.fromSeed(
        seedColor: azulElectrico,
        primary: azulElectrico,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: azulElectrico,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulElectrico,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: azulElectrico,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: azulElectrico,
        primary: azulElectrico,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: azulElectrico,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulElectrico,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}