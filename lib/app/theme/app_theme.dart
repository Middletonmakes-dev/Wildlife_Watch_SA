import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const green = Color(0xFF174A3A);
    const sand = Color(0xFFF8F4EA);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.light,
        surface: sand,
      ),
      scaffoldBackgroundColor: sand,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: green),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: green),
        bodyLarge: TextStyle(height: 1.45),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
