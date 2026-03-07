import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF4F72A3),
      onPrimary: Colors.white,
      secondary: Color(0xFF7FA6C8),
      onSecondary: Colors.white,
      tertiary: Color(0xFF203D5E),
      onTertiary: Colors.white,
      surface: Color(0xFFF2F6FB),
      onSurface: Color(0xFF15253A),
      error: Color(0xFFB3261E),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFE8F0F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF8FB5D8),
      onPrimary: Color(0xFF112338),
      secondary: Color(0xFF6F95BE),
      onSecondary: Color(0xFF0E1E31),
      tertiary: Color(0xFFA2C5E2),
      onTertiary: Color(0xFF0E1E31),
      surface: Color(0xFF0F1C2C),
      onSurface: Color(0xFFD8E7F6),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
