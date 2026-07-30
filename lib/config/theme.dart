import 'package:flutter/material.dart';

class JARVISTheme {
  static const Color primary = Color(0xFF00D4FF);
  static const Color secondary = Color(0xFF7B2FF7);
  static const Color accent = Color(0xFFFF6B35);
  static const Color danger = Color(0xFFFF1744);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFEA00);
  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  static const Color textPrimary = Color(0xFFE8E8FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color hologram = Color(0xFF00FF88);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: textSecondary, fontSize: 12, letterSpacing: 1),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, letterSpacing: 1),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: primary, letterSpacing: 2, fontWeight: FontWeight.w500),
      ),
    );
  }
}
