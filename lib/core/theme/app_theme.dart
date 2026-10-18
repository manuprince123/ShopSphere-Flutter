import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF152D2A);
  static const jade = Color(0xFF176B5B);
  static const coral = Color(0xFFFF754E);
  static const canvas = Color(0xFFF8F7F2);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final darkMode = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: jade,
      surface: darkMode ? const Color(0xFF14211F) : canvas,
      primary: jade,
      secondary: coral,
      brightness: brightness,
    );
    final foreground = darkMode ? const Color(0xFFE4F0EC) : ink;
    final cardColor = darkMode ? const Color(0xFF1D2C29) : Colors.white;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: -.8,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: foreground, height: 1.45),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: foreground,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: jade.withValues(alpha: .12),
        elevation: 0,
      ),
    );
  }
}
