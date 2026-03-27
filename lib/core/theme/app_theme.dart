import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme centraliza TODAS as configurações visuais do app.
///
/// Por que centralizar?
/// Se você precisar mudar uma cor, muda em UM lugar e reflete em toda a app.
/// Sem isso, você acaba com cores espalhadas por 30 arquivos diferentes.
///
/// NOTA sobre withOpacity vs withAlpha:
/// - withOpacity(0.5) → API antiga, vai ser deprecada
/// - withAlpha(128)   → API nova, equivalente (0.5 * 255 ≈ 128)
/// Fórmula: alpha = (opacidade * 255).round()
/// Exemplos comuns:
///   0.04 → 10  | 0.06 → 15  | 0.08 → 20  | 0.10 → 25
///   0.12 → 31  | 0.15 → 38  | 0.20 → 51  | 0.25 → 64
///   0.30 → 77  | 0.35 → 89  | 0.40 → 102 | 0.45 → 115
///   0.50 → 128 | 0.55 → 140 | 0.60 → 153 | 0.65 → 166
///   0.70 → 178 | 0.75 → 191 | 0.80 → 204 | 0.85 → 217
///   0.90 → 230 | 0.95 → 242 | 1.00 → 255
class AppTheme {
  // ─── Cores base (light) ───────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF0D1B2A); // navy escuro
  static const Color accentColor = Color(0xFFC8960C);  // gold
  static const Color backgroundColor = Color(0xFFF4F6F8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);

  // ─── Cores dark ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0F14);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1C2535);
  static const Color darkSurfaceVariant = Color(0xFF1E2A3A);

  // ─── Espaçamentos ─────────────────────────────────────────────────────────
  static const double paddingScreen = 20.0;
  static const double paddingCard = 16.0;
  static const double spacingBetween = 12.0;

  // ─── Border Radius ────────────────────────────────────────────────────────
  static const double radiusCard = 16.0;
  static const double radiusChip = 8.0;
  static const double radiusModal = 24.0;

  // ─── Temas ────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: backgroundColor,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        // surfaceVariant foi renomeado para surfaceContainerHighest no Material 3
        surfaceContainerHighest: Color(0xFFEEF0F3),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: errorColor,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: const Color(0xFFEEF0F3),
        borderColor: Color(0xFFD1D5DB),
        focusColor: primaryColor,
        errorColor: errorColor,
        labelColor: Color(0xFF6B7280),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: darkBackground,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
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
          borderRadius:
              BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: darkSurfaceVariant,
        borderColor: Color(0xFF374151),
        focusColor: accentColor,
        errorColor: errorColor,
        labelColor: Color(0xFF9CA3AF),
      ),
    );
  }

  /// Tema padrão para todos os TextFormField do app.
  /// Definido aqui para não repetir em cada tela.
  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
    required Color errorColor,
    required Color labelColor,
  }) {
    final radius = BorderRadius.circular(radiusChip);
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(color: labelColor, fontSize: 14),
      border: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: focusColor, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: errorColor)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: errorColor, width: 1.8)),
    );
  }
}
