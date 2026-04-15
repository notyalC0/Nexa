import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/widgets/app_shimmer.dart';
import 'package:nexa/features/goals/models/goal_progress.dart';
import 'package:nexa/features/insights/providers/analytics_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _shortMonth(String month) {
  final parts = month.split('-');
  if (parts.length < 2) return month;
  const names = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  final m = (int.tryParse(parts[1]) ?? 1).clamp(1, 12);
  return names[m - 1];
}

String _fullMonth(String month) {
  final parts = month.split('-');
  if (parts.length < 2) return month;
  const names = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  final m = (int.tryParse(parts[1]) ?? 1).clamp(1, 12);
  return '${names[m - 1]} ${parts[0]}';
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return Colors.grey;
  }
}

IconData _categoryIcon(String name) {
  const map = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'label_outline': Icons.label_outline_rounded,
    'payments': Icons.payments_rounded,
    'work': Icons.work_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'home': Icons.home_rounded,
    'home_outlined': Icons.home_outlined,
    'flight': Icons.flight_rounded,
    'school': Icons.school_rounded,
    'attach_money': Icons.attach_money_rounded,
    'savings': Icons.savings_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'movie': Icons.movie_rounded,
    'music_note': Icons.music_note_rounded,
    'pets': Icons.pets_rounded,
    'phone': Icons.phone_rounded,
    'computer': Icons.computer_rounded,
    'wifi': Icons.wifi_rounded,
    'bolt': Icons.bolt_rounded,
    'water_drop': Icons.water_drop_rounded,
    'trending_up': Icons.trending_up_rounded,
    'category': Icons.category_rounded,
  };
  return map[name] ?? Icons.category_rounded;
}

IconData _goalIcon(String name) {
  const map = <String, IconData>{
    'shield': Icons.shield_rounded,
    'flag': Icons.flag_rounded,
    'home': Icons.home_rounded,
    'flight': Icons.flight_rounded,
    'directions_car': Icons.directions_car_rounded,
    'school': Icons.school_rounded,
    'favorite': Icons.favorite_rounded,
    'payments': Icons.payments_rounded,
  };
  return map[name] ?? Icons.flag_rounded;
}

// Navega para o mês anterior
void _prevMonth(WidgetRef ref) {
  final current = ref.read(selectedMonthProvider);
  final parts = current.split('-');
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]) - 1, 1);
  ref.read(selectedMonthProvider.notifier).state =
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}

// Navega para o próximo mês (limitado ao mês atual)
void _nextMonth(WidgetRef ref) {
  final current = ref.read(selectedMonthProvider);
  final parts = current.split('-');
  final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 1);
  final now = DateTime.now();
  if (dt.isAfter(DateTime(now.year, now.month))) return;
  ref.read(selectedMonthProvider.notifier).state =
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}

bool _isCurrentMonth(String month) {
  final now = DateTime.now();
  return month == '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

// ─── InsightsScreen ───────────────────────────────────────────────────────────

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final month = ref.watch(selectedMonthProvider);
    final analyticsAsync = ref.watch(analyticsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              elevation: 0,
              scrolledUnderElevation: 4,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black.withAlpha(60),
              backgroundColor: cs.primary,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: Text(
                'Análise',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cs.primary,
                        Color.lerp(cs.primary, Colors.black, 0.14)!,
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MonthSelector(month: month, ref: ref),
                ),
              ),
            ),

            // ── Conteúdo ──────────────────────────────────────────────
            analyticsAsync.when(
              loading: () => const _LoadingContent(),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: cs.error),
                        const Gap(12),
                        Text(
                          'Não foi possível carregar os dados.',
                          style: AppTheme.subtitleStyle(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (data) => _InsightsContent(data: data, month: month),
            ),

            const SliverToBoxAdapter(child: Gap(100)),
          ],
        ),
      ),
    );
  }
}

// ─── _MonthSelector ───────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final String month;
  final WidgetRef ref;

  const _MonthSelector({required this.month, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNow = _isCurrentMonth(month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavArrow(
          icon: Icons.chevron_left_rounded,
          onTap: () => _prevMonth(ref),
        ),
        const Gap(12),
        Text(
          _fullMonth(month),
          style: TextStyle(
            color: cs.onPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const Gap(12),
        _NavArrow(
          icon: Icons.chevron_right_rounded,
          onTap: isNow ? null : () => _nextMonth(ref),
          disabled: isNow,
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavArrow({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cs.onPrimary.withAlpha(disabled ? 15 : 30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: cs.onPrimary.withAlpha(disabled ? 77 : 200),
          size: 20,
        ),
      ),
    );
  }
}

// ─── _LoadingContent ──────────────────────────────────────────────────────────

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingScreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: AppShimmer(
                      width: double.infinity, height: 80, color: cs.onSurface)),
              const Gap(10),
              Expanded(
                  child: AppShimmer(
                      width: double.infinity, height: 80, color: cs.onSurface)),
              const Gap(10),
              Expanded(
                  child: AppShimmer(
                      width: double.infinity, height: 80, color: cs.onSurface)),
            ]),
            const Gap(20),
            AppShimmer(
                width: double.infinity, height: 220, color: cs.onSurface),
            const Gap(20),
            AppShimmer(
                width: double.infinity, height: 180, color: cs.onSurface),
          ],
        ),
      ),
    );
  }
}

// ─── _InsightsContent ─────────────────────────────────────────────────────────

class _InsightsContent extends StatelessWidget {
  final AnalyticsData data;
  final String month;

  const _InsightsContent({required this.data, required this.month});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.paddingScreen,
          AppTheme.paddingScreen,
          AppTheme.paddingScreen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Resumo do mês ────────────────────────────────────
            _SummaryRow(data: data),
            const Gap(22),

            // ── 2. Evolução mensal (BarChart) ───────────────────────
            _SectionLabel('Evolução mensal'),
            const Gap(10),
            _TrendCard(data: data),
            const Gap(22),

            // ── 3. Gastos por categoria ─────────────────────────────
            if (data.topCategories.isNotEmpty) ...[
              _SectionLabel('Maiores gastos do mês'),
              const Gap(10),
              _CategoriesCard(data: data),
              const Gap(22),
            ],

            // ── 4. Gastos por cartão de crédito ─────────────────────
            if (data.hasCardExpenses) ...[
              _SectionLabel('Gastos com cartões'),
              const Gap(10),
              _CardExpensesCard(data: data),
              const Gap(22),
            ],

            // ── 5. Orçamento (salário configurado) ──────────────────
            if (data.hasSalary) ...[
              _SectionLabel('Orçamento mensal'),
              const Gap(10),
              _BudgetCard(data: data),
              const Gap(22),
            ],

            // ── 6. Metas ────────────────────────────────────────────
            if (data.hasGoals) ...[
              _SectionLabel('Metas'),
              const Gap(10),
              _GoalsCard(goals: data.goals),
              const Gap(22),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── _SummaryRow ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final AnalyticsData data;
  const _SummaryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final balanceColor =
        data.balanceCents >= 0 ? const Color(0xFF2ECC71) : Colors.redAccent;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Receitas',
            cents: data.currentIncomeCents,
            color: const Color(0xFF2ECC71),
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        const Gap(10),
        Expanded(
          child: _SummaryTile(
            label: 'Despesas',
            cents: data.currentExpensesCents,
            color: Colors.redAccent,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const Gap(10),
        Expanded(
          child: _SummaryTile(
            label: 'Saldo',
            cents: data.balanceCents.abs(),
            color: balanceColor,
            icon: data.balanceCents >= 0
                ? Icons.account_balance_wallet_rounded
                : Icons.warning_amber_rounded,
            prefixMinus: data.balanceCents < 0,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int cents;
  final Color color;
  final IconData icon;
  final bool prefixMinus;

  const _SummaryTile({
    required this.label,
    required this.cents,
    required this.color,
    required this.icon,
    this.prefixMinus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(25) : color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(140),
              letterSpacing: 0.4,
            ),
          ),
          const Gap(3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${prefixMinus ? '-' : ''}${CurrencyFormatter.format(cents)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _TrendCard ───────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final AnalyticsData data;
  const _TrendCard({required this.data});

  static const _incomeColor = Color(0xFF2ECC71);
  static const _expenseColor = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trend = data.trend;

    if (trend.isEmpty) {
      return _EmptyCard(
        icon: Icons.bar_chart_rounded,
        message: 'Sem dados para exibir',
      );
    }

    final allValues =
        trend.expand((t) => [t.incomeCents / 100.0, t.expensesCents / 100.0]);
    final maxVal =
        allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 100.0 : (maxVal * 1.25);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legenda
          Row(
            children: [
              _LegendDot(color: _incomeColor, label: 'Receita'),
              const Gap(16),
              _LegendDot(color: _expenseColor, label: 'Despesa'),
            ],
          ),
          const Gap(18),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barGroups: trend.asMap().entries.map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 5,
                    barRods: [
                      BarChartRodData(
                        toY: t.incomeCents / 100.0,
                        color: _incomeColor,
                        width: 11,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                      BarChartRodData(
                        toY: t.expensesCents / 100.0,
                        color: _expenseColor,
                        width: 11,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _shortMonth(trend[i].month),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withAlpha(130),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.onSurface.withAlpha(15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        CurrencyFormatter.format((rod.toY * 100).round()),
                        TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isIncome ? _incomeColor : _expenseColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _CategoriesCard ──────────────────────────────────────────────────────────

class _CategoriesCard extends StatelessWidget {
  final AnalyticsData data;
  const _CategoriesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = data.topCategories;
    final total = categories.fold<int>(0, (s, c) => s + c.totalCents);

    return _Card(
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final color = _hexColor(cat.colorHex);
          final pct = total == 0 ? 0.0 : cat.totalCents / total;

          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 20,
                  color: cs.onSurface.withAlpha(12),
                ),
              Row(
                children: [
                  // Ícone
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(cat.icon),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const Gap(12),
                  // Nome + barra
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                cat.name,
                                style: AppTheme.actionStyle(context,
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              CurrencyFormatter.format(cat.totalCents),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: pct.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: cs.onSurface.withAlpha(18),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                            const Gap(8),
                            Text(
                              '${(pct * 100).round()}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── _CardExpensesCard ───────────────────────────────────────────────────────

Color _bankColor(String? colorHex, String bankKeyword) {
  if (colorHex != null && colorHex.isNotEmpty) return _hexColor(colorHex);
  final kw = bankKeyword.toLowerCase();
  if (kw.contains('nubank')) return const Color(0xFF8B5CF6);
  if (kw.contains('inter')) return const Color(0xFFFF6B00);
  if (kw.contains('bradesco')) return const Color(0xFFCC0000);
  if (kw.contains('itau') || kw.contains('itaú')) {
    return const Color(0xFFFF6600);
  }
  if (kw.contains('santander')) return const Color(0xFFEC0000);
  if (kw.contains('c6')) return const Color(0xFF1A1A2E);
  if (kw.contains('xp')) return const Color(0xFF222222);
  if (kw.contains('bb') || kw.contains('brasil')) {
    return const Color(0xFF003399);
  }
  if (kw.contains('caixa')) return const Color(0xFF005CA9);
  if (kw.contains('sicoob')) return const Color(0xFF009343);
  return const Color(0xFF5B5F97);
}

class _CardExpensesCard extends StatelessWidget {
  final AnalyticsData data;
  const _CardExpensesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cards = data.cardExpenses;
    final totalCard = data.totalCardExpensesCents;
    final totalCash = data.cashExpensesCents;
    final totalAll = totalCard + totalCash;
    final cardPct = totalAll == 0 ? 0.0 : totalCard / totalAll;
    final cashPct = totalAll == 0 ? 0.0 : totalCash / totalAll;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Split cartão vs débito/dinheiro
          Row(
            children: [
              Expanded(
                child: _SplitTile(
                  label: 'Cartão de crédito',
                  cents: totalCard,
                  pct: cardPct,
                  color: const Color(0xFF4D96FF),
                  icon: Icons.credit_card_rounded,
                ),
              ),
              const Gap(10),
              Expanded(
                child: _SplitTile(
                  label: 'Débito / Dinheiro',
                  cents: totalCash,
                  pct: cashPct,
                  color: const Color(0xFF2ECC71),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),

          if (cards.isNotEmpty) ...[
            const Gap(16),
            Divider(height: 1, color: cs.onSurface.withAlpha(14)),
            const Gap(16),
            ...cards.asMap().entries.map((entry) {
              final i = entry.key;
              final card = entry.value;
              final color = _bankColor(card.colorHex, card.bankKeyword);
              final pct = totalCard == 0 ? 0.0 : card.totalCents / totalCard;

              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 20, color: cs.onSurface.withAlpha(12)),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.credit_card_rounded,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    card.name,
                                    style: AppTheme.actionStyle(context,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  CurrencyFormatter.format(card.totalCents),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: pct.clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor:
                                          cs.onSurface.withAlpha(18),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  '${(pct * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface.withAlpha(120),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SplitTile extends StatelessWidget {
  final String label;
  final int cents;
  final double pct;
  final Color color;
  final IconData icon;

  const _SplitTile({
    required this.label,
    required this.cents,
    required this.pct,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pctDisplay = (pct * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(20) : color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const Gap(5),
              Text(
                '$pctDisplay%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withAlpha(130),
            ),
          ),
          const Gap(3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(cents),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _BudgetCard ──────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final AnalyticsData data;
  const _BudgetCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = data.expenseToSalaryRatio.clamp(0.0, 1.0);
    final over = data.expenseToSalaryRatio > 1.0;
    final pctDisplay = (data.expenseToSalaryRatio * 100).round();

    final barColor = over
        ? Colors.redAccent
        : pct > 0.75
            ? Colors.orangeAccent
            : const Color(0xFF2ECC71);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salário mensal',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(130),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    CurrencyFormatter.format(data.salaryCents),
                    style: AppTheme.titleStyle(context, fontSize: 17),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: barColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: barColor.withAlpha(80)),
                ),
                child: Text(
                  over ? 'Acima do limite' : '$pctDisplay% usado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: cs.onSurface.withAlpha(18),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gasto: ${CurrencyFormatter.format(data.currentExpensesCents)}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withAlpha(150),
                ),
              ),
              Text(
                'Disponível: ${CurrencyFormatter.format((data.salaryCents - data.currentExpensesCents).clamp(0, double.maxFinite.toInt()))}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── _GoalsCard ───────────────────────────────────────────────────────────────

class _GoalsCard extends StatelessWidget {
  final List<GoalProgress> goals;

  const _GoalsCard({required this.goals});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...goals.asMap().entries.map((entry) {
            final index = entry.key;
            final goal = entry.value;
            final color = _hexColor(goal.goal.colorHex);
            final reached = goal.isReached;
            final pct = goal.progress.clamp(0.0, 1.0);
            final pctDisplay = (goal.progress * 100).round();
            final estimateLabel = reached
                ? 'Meta atingida'
                : goal.estimatedReachDate == null
                    ? 'Estimativa: n/a'
                    : 'Estimativa: ${DateFormat('MM/yyyy').format(goal.estimatedReachDate!)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child:
                        Divider(color: cs.onSurface.withAlpha(12), height: 1),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withAlpha(22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _goalIcon(goal.goal.icon),
                              color: color,
                              size: 20,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        goal.goal.name,
                                        style: AppTheme.titleStyle(
                                          context,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (goal.goal.isDefault) ...[
                                      const Gap(8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(18),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          'Reserva',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const Gap(3),
                                Text(
                                  'Atual ${CurrencyFormatter.format(goal.currentAmountCents)} de ${CurrencyFormatter.format(goal.goal.targetAmountCents)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Text(
                      reached ? 'OK' : '$pctDisplay%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: reached ? const Color(0xFF2ECC71) : color,
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: cs.onSurface.withAlpha(18),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      reached ? const Color(0xFF2ECC71) : color,
                    ),
                  ),
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Faltam: ${CurrencyFormatter.format(goal.remainingCents)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(150),
                      ),
                    ),
                    Text(
                      estimateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withAlpha(80)
            : cs.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cs.onSurface.withAlpha(14)),
      ),
      child: child,
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: cs.onSurface.withAlpha(60)),
            const Gap(10),
            Text(
              message,
              style: AppTheme.subtitleStyle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
