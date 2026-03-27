import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';

/// Cabeçalho de seção da tela de configurações.
///
/// Extraído para arquivo próprio porque é usado repetidamente
/// em settings_screen.dart e poderia ser reutilizado em outras telas.
///
/// Exemplo:
/// ```dart
/// SettingsSectionHeader(label: 'Finanças')
/// SettingsSectionHeader(label: 'Aparência')
/// ```
class SettingsSectionHeader extends StatelessWidget {
  final String label;

  const SettingsSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(115),
      ),
    );
  }
}

/// Tile de configuração com ícone, título, subtítulo e trailing widget.
///
/// O trailing pode ser qualquer widget:
///   - Icon (para ações de navegação)
///   - Switch (para toggles)
///   - Text (para exibir valores)
///
/// Extraído para evitar repetição — o settings_screen tinha ~8 tiles
/// com o mesmo Container + Row + Column, diferindo só no conteúdo.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingCard, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: cs.onSurface.withAlpha(20)),
        ),
        child: Row(
          children: [
            // Ícone com fundo colorido
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: effectiveIconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Icon(icon, size: 18, color: effectiveIconColor),
            ),
            const Gap(12),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(127),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
