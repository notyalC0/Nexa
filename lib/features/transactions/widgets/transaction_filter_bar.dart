import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';

/// Opção de filtro (modelo de dados simples — sem lógica de UI)
class FilterOption {
  final String? value;
  final String label;
  final IconData icon;

  const FilterOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Barra de filtro com navegação de mês e chips de tipo de transação.
///
/// Extraída do home_screen.dart para manter o arquivo principal menor.
/// Toda lógica de estado fica no pai (home_screen) — este widget é "puro"
/// (só recebe dados e dispara callbacks).
class TransactionFilterBar extends StatelessWidget {
  final String monthLabel;
  final bool isFutureMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String? selectedFilter;
  final List<FilterOption> filters;
  final ValueChanged<String?> onFilterChanged;

  const TransactionFilterBar({
    super.key,
    required this.monthLabel,
    required this.isFutureMonth,
    required this.onPrevious,
    required this.onNext,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Navegação de mês ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen, vertical: 6),
            child: Row(
              children: [
                _MonthArrowButton(
                    icon: Icons.chevron_left_rounded, onTap: onPrevious),
                const Gap(4),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthLabel,
                          style: AppTheme.titleStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (isFutureMonth) ...[
                          const Gap(6),
                          _FutureMonthBadge(),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(4),
                _MonthArrowButton(
                    icon: Icons.chevron_right_rounded, onTap: onNext),
              ],
            ),
          ),

          // ── Chips de filtro ───────────────────────────────────────
          SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingScreen),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) {
                final f = filters[index];
                final isActive = selectedFilter == f.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: isActive
                          ? cs.primary
                          : cs.surfaceContainerHighest.withAlpha(127),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isActive ? cs.primary : cs.onSurface.withAlpha(25),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onFilterChanged(f.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                f.icon,
                                size: 20,
                                color: isActive
                                    ? cs.onPrimary
                                    : cs.onSurface.withAlpha(153),
                              ),
                              const Gap(5),
                              Text(
                                f.label,
                                style: AppTheme.metaStyle(
                                  context,
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? cs.onPrimary
                                      : cs.onSurface.withAlpha(153),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(6),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.onSurface.withAlpha(15),
          ),
        ],
      ),
    );
  }
}

/// Badge "Projetado" exibido ao navegar para meses futuros
class _FutureMonthBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withAlpha(102)),
      ),
      child: Text(
        'Projetado',
        style: AppTheme.metaStyle(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }
}

/// Botão de seta para navegar entre meses
class _MonthArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MonthArrowButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(127),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Icon(icon, size: 22, color: cs.onSurface.withAlpha(178)),
      ),
    );
  }
}

/// Delegate para fixar o FilterBar na tela durante scroll
class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  static const double _height = 120;

  const StickyFilterDelegate({required this.child});

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(StickyFilterDelegate old) => old.child != child;
}
