import 'package:flutter/material.dart';

class AppTheme {
  // --- Cores base ---
  static const Color primaryColor = Color(0xFF0D1B2A); // navy escuro
  static const Color accentColor = Color(0xFFC8960C); // gold
  static const Color backgroundColor = Color(0xFFF4F6F8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);

  // --- Dark mode ---
  static const Color darkBackground = Color(0xFF0A0F14);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1C2535);
  static const Color darkSurfaceVariant = Color(0xFF1E2A3A);

  // --- Espaçamentos ---
  static const double paddingScreen = 20.0;
  static const double paddingCard = 16.0;
  static const double spacingBetween = 12.0;

  // --- Border Radius ---
  static const double radiusCard = 16.0;
  static const double radiusChip = 8.0;
  static const double radiusModal = 24.0;

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        surfaceContainerHighest: Color(0xFFEEF0F3),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: errorColor,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: darkBackground,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        // No dark, o gold assume o papel de cor de ação (visível)
        primary: accentColor,
        secondary: accentColor,
        surface: darkCard,
        surfaceContainerHighest: darkSurfaceVariant,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        error: errorColor,
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
    );
  }
}
