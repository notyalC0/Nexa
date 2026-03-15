import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/features/cards/screens/card_screen.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/home/widgets/health_score_card.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/settings/screens/settings_screen.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/screens/add_transactions_screen.dart';
import '../../transactions/widgets/transaction_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _TransactionsPage(),
            CardsScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions Page — StatefulWidget para gerenciar mês e filtro localmente
// ---------------------------------------------------------------------------

class _TransactionsPage extends ConsumerStatefulWidget {
  const _TransactionsPage();

  @override
  ConsumerState<_TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<_TransactionsPage> {
  // Mês selecionado — inicia no mês atual
  late DateTime _selectedMonth;
  // Filtro de tipo: null = todos
  String? _selectedFilter;

  static const _filters = [
    _FilterOption(value: null, label: 'Todos', icon: Icons.list_rounded),
    _FilterOption(
        value: 'income', label: 'Receitas', icon: Icons.arrow_upward_rounded),
    _FilterOption(
        value: 'expense',
        label: 'Despesas',
        icon: Icons.arrow_downward_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(selectedMonthProvider.notifier).state =
          _formatMonth(_selectedMonth);
    });
  }

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _updateSelectedMonth(DateTime month) {
    setState(() {
      _selectedMonth = month;
    });
    ref.read(selectedMonthProvider.notifier).state = _formatMonth(month);
  }

  void _previousMonth() {
    _updateSelectedMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month - 1),
    );
  }

  void _nextMonth() {
    _updateSelectedMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month + 1),
    );
  }

  bool get _isFutureMonth {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    return _selectedMonth.isAfter(current);
  }

  String get _monthLabel {
    const months = [
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
    final label = months[_selectedMonth.month - 1];
    final now = DateTime.now();
    if (_selectedMonth.year != now.year) {
      return '$label ${_selectedMonth.year}';
    }
    return label;
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Bom dia';
    }
    if (hour >= 12 && hour < 18) {
      return 'Boa tarde';
    }
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceAsync = ref.watch(balanceProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final hideBalance = settingsAsync.maybeWhen(
      data: (value) => value.hideBalance,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionsScreen()),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nova transação',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header com saldo
          balanceAsync.when(
            loading: () => _buildHeader(context,
                availableCents: 0,
                projectedCents: 0,
                incomeCents: 0,
                expensesCents: 0,
                isLoading: true,
                hideBalance: hideBalance),
            error: (_, __) => _buildHeader(context,
                availableCents: 0,
                projectedCents: 0,
                incomeCents: 0,
                expensesCents: 0,
                isLoading: false,
                hideBalance: hideBalance),
            data: (balance) => _buildHeader(context,
                availableCents: balance.availableCents,
                projectedCents: balance.projectCents,
                incomeCents: balance.incomeCents,
                expensesCents: balance.expensesCents,
                isLoading: false,
                hideBalance: hideBalance),
          ),

          // Health card
          const SliverToBoxAdapter(child: Gap(8)),
          SliverToBoxAdapter(
            child: ref.watch(healthScoreProvider).when(
                  loading: () => const HealthScoreCard(score: 0),
                  error: (_, __) => const HealthScoreCard(score: 0),
                  data: (score) => HealthScoreCard(score: score),
                ),
          ),
          const SliverToBoxAdapter(child: Gap(12)),

          // Seletor de mês + filtros — sticky abaixo do header colapsado
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterDelegate(
              child: _FilterBar(
                monthLabel: _monthLabel,
                isFutureMonth: _isFutureMonth,
                onPrevious: _previousMonth,
                onNext: _nextMonth,
                selectedFilter: _selectedFilter,
                filters: _filters,
                onFilterChanged: (v) => setState(() => _selectedFilter = v),
              ),
            ),
          ),

          // Lista de transações
          _buildTransactionsList(ref, context),
          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }



  Future<bool> _confirmDeleteSingleTransaction(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir transação'),
        content: const Text('Tem certeza que deseja excluir esta transação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<bool> _handleDeleteTransaction(BuildContext context, Transactions transaction) async {
    final canDeleteInstallmentsTogether =
        transaction.creditCardsId != null &&
        (transaction.installmentTotal ?? 1) > 1 &&
        (transaction.installmentGroupId?.isNotEmpty ?? false);

    if (!canDeleteInstallmentsTogether) {
      final confirmed = await _confirmDeleteSingleTransaction(context);
      if (!confirmed) return false;

      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
      return true;
    }

    final deleteOption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir compra parcelada'),
        content: const Text('Deseja excluir somente esta parcela ou todas as parcelas desta compra no cartão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'current'),
            child: const Text('Só parcela atual'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: const Text('Todas parcelas'),
          ),
        ],
      ),
    );

    if (deleteOption == 'current') {
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
      return true;
    }

    if (deleteOption == 'all') {
      await DatabaseHelper.instance
          .deleteGroupTransaction(transaction.installmentGroupId!);
      return true;
    }

    return false;
  }

  Widget _buildHeader(
    BuildContext context, {
    required int availableCents,
    required int projectedCents,
    required int incomeCents,
    required int expensesCents,
    required bool isLoading,
    required bool hideBalance,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingScreen,
            0,
            AppTheme.paddingScreen,
            AppTheme.paddingScreen,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${getGreeting()} 👋',
                  style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const Gap(2),
              Text('Saldo disponível',
                  style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.65),
                      fontSize: 12,
                      letterSpacing: 0.3)),
              const Gap(2),
              if (isLoading)
                _ShimmerText(
                    width: 160, height: 36, color: colorScheme.onPrimary)
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    
                    Text(hideBalance ? '••••' : CurrencyFormatter.format(availableCents),
                        style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1)),
                  ],
                ),
              const Gap(12),
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: _BalancePill(
                      label: 'Receitas',
                      cents: isLoading ? null : incomeCents,
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF2ECC71),
                      onPrimary: colorScheme.onPrimary,
                    ),
                  ),
                  const Gap(8),
                  Flexible(
                    fit: FlexFit.tight,
                    child: _BalancePill(
                      label: 'Despesas',
                      cents: isLoading ? null : expensesCents,
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.redAccent,
                      onPrimary: colorScheme.onPrimary,
                    ),
                  ),
                  const Gap(8),
                  Flexible(
                    fit: FlexFit.tight,
                    child: _BalancePill(
                      label: 'Projetado',
                      cents: isLoading ? null : projectedCents,
                      icon: Icons.arrow_outward_rounded,
                      color: Colors.yellowAccent,
                      onPrimary: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(WidgetRef ref, BuildContext context) {
    final month = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final transactionsAsync = ref.watch(transactionsByMonthProvider(month));

    return transactionsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingScreen),
          child: _EmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Erro ao carregar transações',
          ),
        ),
      ),
      data: (transactions) {
        final filtered = _selectedFilter == null
            ? transactions
            : transactions.where((t) => t.type == _selectedFilter).toList();

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingScreen),
              child: _EmptyState(
                icon: _selectedFilter != null
                    ? Icons.filter_list_off_rounded
                    : Icons.receipt_long_outlined,
                message: _selectedFilter != null
                    ? 'Nenhuma transação com este filtro'
                    : 'Nenhuma transação em $_monthLabel',
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => TransactionCard(
              transaction: filtered[index],
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddTransactionsScreen(transaction: filtered[index]),
                ),
              ),
              onDeleteWithContext: (dialogContext) =>
                  _handleDeleteTransaction(dialogContext, filtered[index]),
              onDelete: () {
                ref.invalidate(transactionsProvider);
                ref.invalidate(healthScoreProvider);
                ref.invalidate(balanceProvider);
              },
            ),
            childCount: filtered.length,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Barra de filtro (mês + chips) — fica sticky no topo ao scrollar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final String monthLabel;
  final bool isFutureMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String? selectedFilter;
  final List<_FilterOption> filters;
  final ValueChanged<String?> onFilterChanged;

  const _FilterBar({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seletor de mês
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingScreen,
              vertical: 6,
            ),
            child: Row(
              children: [
                // Botão anterior
                _MonthArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrevious,
                ),
                const Gap(4),
                // Label do mês + badge "Projetado" quando for mês futuro
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (isFutureMonth) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.yellowAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.yellowAccent.withOpacity(0.4)),
                            ),
                            child: Text(
                              'Projetado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(4),
                // Botão próximo — sempre habilitado
                _MonthArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: onNext,
                ),
              ],
            ),
          ),

          // Chips de filtro — scroll horizontal
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isActive = selectedFilter == filter.value;

                return GestureDetector(
                  onTap: () => onFilterChanged(filter.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter.icon,
                          size: 13,
                          color: isActive
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const Gap(5),
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Gap(6),

          // Separador sutil
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.onSurface.withOpacity(0.06),
          ),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _MonthArrow({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled
              ? colorScheme.onSurface.withOpacity(0.2)
              : colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

// SliverPersistentHeaderDelegate para o filtro sticky
class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  // Altura = seletor de mês (44) + chips (36) + gap (6) + divider (1) = ~87
  static const double _height = 87;

  const _StickyFilterDelegate({required this.child});

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyFilterDelegate oldDelegate) =>
      oldDelegate.child != child;
}

// Modelo de opção de filtro
class _FilterOption {
  final String? value;
  final String label;
  final IconData icon;

  const _FilterOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

// ---------------------------------------------------------------------------
// Bottom Nav Bar
// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.onSurface.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Início',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.credit_card_outlined,
                activeIcon: Icons.credit_card_rounded,
                label: 'Cartões',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Config.',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withOpacity(0.4);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _BalancePill extends StatelessWidget {
  final String label;
  final int? cents;
  final IconData icon;
  final Color color;
  final Color onPrimary;

  const _BalancePill({
    required this.label,
    required this.cents,
    required this.icon,
    required this.color,
    required this.onPrimary,
  });

  String _compact(int cents) {
    final value = cents / 100;
    if (value >= 1000000) {
      final m = value / 1000000;
      return '${m.toStringAsFixed(m < 10 ? 1 : 0)}M';
    }
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = cents == null ? '—' : _compact(cents!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: onPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: onPrimary.withOpacity(0.6),
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                Text('R\$ $displayValue',
                    style: TextStyle(
                        fontSize: 12,
                        color: onPrimary,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerText extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const _ShimmerText({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gap(24),
        Icon(icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
        const Gap(12),
        Text(message,
            style: TextStyle(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        const Gap(24),
      ],
    );
  }
}
