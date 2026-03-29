import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';

/// Widget genérico de "estado vazio" — usado quando uma lista não tem itens.
///
/// Separado em arquivo próprio para ser reutilizado na tela de transações,
/// cartões, etc. sem duplicar código.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gap(24),
        Icon(icon, size: 48, color: cs.onSurface.withAlpha(50)),
        const Gap(12),
        Text(
          message,
          style: AppTheme.actionStyle(
            context,
            fontSize: 14,
            color: cs.onSurface.withAlpha(100),
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const Gap(6),
          Text(
            subtitle!,
            style: AppTheme.metaStyle(
              context,
              fontSize: 12,
              color: cs.onSurface.withAlpha(70),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const Gap(16),
          action!,
        ],
        const Gap(24),
      ],
    );
  }
}
