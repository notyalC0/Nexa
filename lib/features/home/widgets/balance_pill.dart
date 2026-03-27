import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/widgets/app_shimmer.dart' show AppShimmer;

/// Pill pequena exibida no header da home com resumo financeiro.
///
/// Exibe: Receitas, Despesas ou Projetado.
/// Separada do home_screen.dart para reduzir o tamanho do arquivo
/// e facilitar testes e manutenção.
class BalancePill extends StatelessWidget {
  final String label;
  final int? cents;
  final IconData icon;
  final Color color;
  final Color onPrimary;
  final bool isLoading;

  const BalancePill({
    super.key,
    required this.label,
    required this.cents,
    required this.icon,
    required this.color,
    required this.onPrimary,
    this.isLoading = false,
  });

  String _compact(int cents) {
    final v = cents / 100;
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m.toStringAsFixed(m < 10 ? 1 : 0)}M';
    }
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: onPrimary.withAlpha(25),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 11, color: color),
          ),
          const Gap(6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: onPrimary.withAlpha(153),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isLoading)
                  AppShimmer(width: 44, height: 14, color: onPrimary)
                else
                  Text(
                    'R\$ ${_compact(cents ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
