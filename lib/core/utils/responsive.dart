import 'package:flutter/material.dart';

/// Breakpoints e helpers de responsividade.
///
/// O design do Nexa foi pensado para mobile. Para telas maiores,
/// usamos NavigationRail em vez de BottomNavigationBar e adaptamos
/// os layouts com grids e padding generosos.
class Responsive {
  Responsive._();

  /// Breakpoint: abaixo é considerado mobile
  static const double mobileMax = 600;

  /// Breakpoint: tablet / tela média
  static const double tabletMin = 600;

  /// Breakpoint: acima é desktop
  static const double desktopMin = 1024;

  /// Largura máxima do conteúdo de formulários (settings, add transaction)
  static const double maxFormWidth = 640;

  /// Largura máxima para conteúdo de página (cards, insights)
  static const double maxPageWidth = 960;

  /// Retorna true se a tela é estreita (celular)
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  /// Retorna true se a tela é larga o suficiente para usar NavigationRail
  static bool useNavRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax;

  /// Retorna true se a tela é grande (desktop)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMin;

  /// Padding horizontal adaptativo para conteúdo de página.
  /// Mobile: 20, Tablet: 32, Desktop: 48
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktopMin) return 48;
    if (w >= tabletMin) return 32;
    return 20; // AppTheme.paddingScreen
  }

  /// Retorna 2 colunas no desktop, 1 no mobile/tablet
  static int gridColumns(BuildContext context) => isDesktop(context) ? 2 : 1;

  /// Espaçamento entre colunas do grid
  static const double gridSpacing = 16;
}
