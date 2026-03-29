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
  static const Color accentColor = Color(0xFFC8960C); // gold
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
      textTheme: _buildTextTheme(
        brightness: Brightness.light,
        primaryTextColor: textPrimary,
        secondaryTextColor: textSecondary,
      ),
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
          borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusModal),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusModal)),
        ),
      ),
      snackBarTheme: _snackBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      switchTheme: _switchTheme(
        activeColor: primaryColor,
        inactiveTrackColor: const Color(0xFFB6BFCA),
        inactiveThumbColor: const Color(0xFFF8FAFC),
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
      textTheme: _buildTextTheme(
        brightness: Brightness.dark,
        primaryTextColor: Colors.white,
        secondaryTextColor: const Color(0xFFB8C0CC),
      ),
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
          borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusModal),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusModal)),
        ),
      ),
      snackBarTheme: _snackBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
      ),
      switchTheme: _switchTheme(
        activeColor: accentColor,
        inactiveTrackColor: const Color(0xFF556070),
        inactiveThumbColor: const Color(0xFFE5E7EB),
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

  static SwitchThemeData _switchTheme({
    required Color activeColor,
    required Color inactiveTrackColor,
    required Color inactiveThumbColor,
  }) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return activeColor;
        return inactiveThumbColor;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return activeColor.withAlpha(102);
        }
        return inactiveTrackColor;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  static TextTheme _buildTextTheme({
    required Brightness brightness,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final baseMaterial = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final poppins = GoogleFonts.poppinsTextTheme(baseMaterial).apply(
      bodyColor: primaryTextColor,
      displayColor: primaryTextColor,
    );

    return poppins.copyWith(
      headlineSmall:
          poppins.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: poppins.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: poppins.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: poppins.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: poppins.bodyLarge?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: poppins.bodyMedium?.copyWith(
        color: primaryTextColor,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: poppins.bodySmall?.copyWith(
        color: secondaryTextColor,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: poppins.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: poppins.labelMedium?.copyWith(
        color: secondaryTextColor,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: poppins.labelSmall?.copyWith(
        color: secondaryTextColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      contentTextStyle: TextStyle(
        color: foregroundColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: accentColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      border:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: focusColor, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: errorColor)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: errorColor, width: 1.8)),
    );
  }

  static TextStyle inputTextStyle(
    BuildContext context, {
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: cs.onSurface,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle inputPrefixStyle(
    BuildContext context, {
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: cs.onSurface,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle inputHintStyle(
    BuildContext context, {
    double fontSize = 14,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: cs.onSurface.withAlpha(153),
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle titleStyle(
    BuildContext context, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: color ?? cs.onSurface,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle subtitleStyle(
    BuildContext context, {
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: color ?? cs.onSurface.withAlpha(166),
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle metaStyle(
    BuildContext context, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: color ?? cs.onSurface.withAlpha(140),
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle actionStyle(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      color: color ?? cs.onSurface,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static SnackBar snackBar(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ??
        Theme.of(context).snackBarTheme.backgroundColor ??
        cs.surface;
    final fg = foregroundColor ??
        Theme.of(context).snackBarTheme.contentTextStyle?.color ??
        cs.onSurface;

    return SnackBar(
      backgroundColor: bg,
      content: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    IconData? icon,
    String? prefixText,
    EdgeInsetsGeometry? contentPadding,
    bool compact = false,
    bool alignLabelWithHint = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: cs.onSurface.withAlpha(140))
          : null,
      prefixStyle: inputPrefixStyle(
        context,
        fontSize: compact ? 14 : 15,
      ),
      labelStyle: TextStyle(
        color: cs.onSurface.withAlpha(166),
        fontSize: compact ? 13 : 14,
      ),
      floatingLabelStyle: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withAlpha(102),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusChip),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusChip),
        borderSide: BorderSide(color: cs.onSurface.withAlpha(51)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusChip),
        borderSide: BorderSide(color: cs.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusChip),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusChip),
        borderSide: BorderSide(color: cs.error, width: 1.8),
      ),
      contentPadding: contentPadding ??
          (compact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
              : null),
      isDense: compact,
      alignLabelWithHint: alignLabelWithHint,
    );
  }
}
