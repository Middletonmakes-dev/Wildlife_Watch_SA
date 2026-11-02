import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();
  static const rust = Color(0xFFAC4D32);
  static const ink = Color(0xFF202820);
  static const rule = Color(0xFFD0D5CE);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
                seedColor: rust, surface: Colors.white)
            .copyWith(primary: rust, onPrimary: Colors.white, secondary: ink),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontFamily: 'JournalSerif',
              fontSize: 34,
              height: 1.08,
              color: ink),
          headlineMedium: TextStyle(
              fontFamily: 'JournalSerif',
              fontSize: 30,
              height: 1.1,
              color: ink),
          titleLarge:
              TextStyle(fontFamily: 'JournalSerif', fontSize: 25, color: ink),
          titleMedium:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
          bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: ink),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: ink),
          bodySmall:
              TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF626E64)),
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: ink,
            elevation: 0,
            titleTextStyle: TextStyle(
                fontFamily: 'JournalSerif', fontSize: 24, color: ink)),
        dividerTheme:
            const DividerThemeData(color: rule, thickness: 1, space: 1),
        inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            filled: true,
            fillColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: rust,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: const RoundedRectangleBorder(),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 48),
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: rule))),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 14))),
        cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: rule))),
      );
}
