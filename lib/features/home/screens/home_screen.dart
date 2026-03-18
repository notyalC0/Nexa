import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/cards/screens/card_screen.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/home/widgets/health_score_card.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/settings/screens/settings_screen.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/screens/add_transactions_screen.dart';
import '../../transactions/widgets/transaction_card.dart';

// ---------------------------------------------------------------------------
// Helpers — fora das classes para evitar recriação a cada build
// ---------------------------------------------------------------------------

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Bom dia';
  if (hour >= 12 && hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

String _formatMonth(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _TransactionsPage(),
            const CardsScreen(),
            const SettingsScreen(),
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
// Transactions Page
// ---------------------------------------------------------------------------

class _TransactionsPage extends ConsumerStatefulWidget {
  const _TransactionsPage();

  @override
  ConsumerState<_TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<_TransactionsPage> {
  late DateTime _selectedMonth;
  String? _selectedFilter;

  // IDs removidos localmente — evita o erro "dismissed Dismissible still in tree"
  // enquanto o provider ainda não reconstruiu a lista
  final Set<int> _dismissedIds = {};

  // greeting calculado uma única vez por instância
  late final String _greetingText;

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
    _greetingText = _greeting();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(selectedMonthProvider.notifier).state =
          _formatMonth(_selectedMonth);
    });
  }

  void _updateSelectedMonth(DateTime month) {
    setState(() => _selectedMonth = month);
    ref.read(selectedMonthProvider.notifier).state = _formatMonth(month);
  }

  void _previousMonth() => _updateSelectedMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() => _updateSelectedMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  bool get _isFutureMonth {
    final now = DateTime.now();
    return _selectedMonth.isAfter(DateTime(now.year, now.month));
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
    if (_selectedMonth.year != DateTime.now().year) {
      return '$label ${_selectedMonth.year}';
    }
    return label;
  }

  // --- Dialogs de exclusão com o tema do app ---

  Future<bool> _confirmDeleteSingle(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusModal),
        ),
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child:
                  Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
            ),
            const Gap(12),
            Text('Excluir transação',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir esta transação? Esta ação não pode ser desfeita.',
          style: TextStyle(
              fontSize: 14, color: cs.onSurface.withOpacity(0.7), height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
            ),
            child: const Text('Excluir',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _handleDeleteTransaction(
      BuildContext context, Transactions transaction) async {
    final cs = Theme.of(context).colorScheme;

    if (transaction.isRecurring) {
      final option = await showDialog<String>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal),
          ),
          backgroundColor: cs.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Icon(Icons.repeat_rounded, color: cs.error, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Text('Transação recorrente',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
            ],
          ),
          content: Text(
            'Deseja deletar apenas esta ou todas as parcelas futuras?',
            style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.7),
                height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'current'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withOpacity(0.5)),
                    ),
                    child: const Text('Só esta'),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'future'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Futuras'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (option == 'current') {
        await DatabaseHelper.instance.deleteTransaction(transaction.id!);
        return true;
      }
      if (option == 'future') {
        await DatabaseHelper.instance
            .deleteTransaction(transaction.id!, deleteAll: true);
        return true;
      }
      return false;
    }

    final canDeleteGroup = transaction.creditCardsId != null &&
        (transaction.installmentTotal ?? 1) > 1 &&
        (transaction.installmentGroupId?.isNotEmpty ?? false);

    if (!canDeleteGroup) {
      final confirmed = await _confirmDeleteSingle(context);
      if (!confirmed) return false;
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
      return true;
    }

    // Dialog de parcelas com tema
    final option = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusModal),
        ),
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Icon(Icons.layers_outlined, color: cs.error, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Text('Compra parcelada',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ),
          ],
        ),
        content: Text(
          'Deseja excluir somente esta parcela ou todas as parcelas desta compra?',
          style: TextStyle(
              fontSize: 14, color: cs.onSurface.withOpacity(0.7), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          // Cancelar ocupa linha própria para não apertar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withOpacity(0.5),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'current'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip)),
                  ),
                  child: const Text('Só esta',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const Gap(10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 'all'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip)),
                  ),
                  child: const Text('Todas',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (option == 'current') {
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
      return true;
    }
    if (option == 'all') {
      await DatabaseHelper.instance
          .deleteGroupTransaction(transaction.installmentGroupId!);
      return true;
    }
    return false;
  }

  void _invalidateAll() {
    ref.invalidate(transactionsByMonthProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(healthScoreProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(cardLimitDetailsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceAsync = ref.watch(balanceProvider);
    final hideBalance = ref.watch(appSettingsProvider).maybeWhen(
          data: (s) => s.hideBalance,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddTransactionsScreen())),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova transação',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        // RepaintBoundary implícito no CustomScrollView já ajuda;
        // não adicionar listeners desnecessários aqui
        slivers: [
          balanceAsync.when(
            loading: () => _buildHeader(context,
                availableCents: 0,
                projectedCents: 0,
                incomeCents: 0,
                expensesCents: 0,
                isLoading: true,
                hideBalance: hideBalance,
                initialBalanceCents: 0),
            error: (_, __) => _buildHeader(context,
                availableCents: 0,
                projectedCents: 0,
                incomeCents: 0,
                expensesCents: 0,
                isLoading: false,
                hideBalance: hideBalance,
                initialBalanceCents: 0),
            data: (b) => _buildHeader(context,
                availableCents: b.availableCents,
                projectedCents: b.projectCents,
                incomeCents: b.incomeCents,
                expensesCents: b.expensesCents,
                isLoading: false,
                hideBalance: hideBalance,
                initialBalanceCents: b.initialBalanceCents),
          ),
          const SliverToBoxAdapter(child: Gap(8)),

          // HealthScoreCard com loading próprio
          SliverToBoxAdapter(
            child: ref.watch(healthScoreProvider).when(
                  loading: () =>
                      const HealthScoreCard(score: 0, isLoading: true),
                  error: (_, __) => const HealthScoreCard(score: 0),
                  data: (score) => HealthScoreCard(score: score),
                ),
          ),
          const SliverToBoxAdapter(child: Gap(12)),

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

          _buildTransactionsList(context),
          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int availableCents,
    required int projectedCents,
    required int incomeCents,
    required int expensesCents,
    required bool isLoading,
    required bool hideBalance,
    required int initialBalanceCents,
  }) {
    final cs = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      elevation: 0,
      backgroundColor: cs.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, cs.primary.withOpacity(0.85)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(AppTheme.paddingScreen, 0,
              AppTheme.paddingScreen, AppTheme.paddingScreen),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_greetingText 👋',
                  style: TextStyle(
                      color: cs.onPrimary.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const Gap(2),
              Text('Saldo disponível',
                  style: TextStyle(
                      color: cs.onPrimary.withOpacity(0.65),
                      fontSize: 12,
                      letterSpacing: 0.3)),
              const Gap(2),

              // Saldo principal
              if (isLoading)
                _Shimmer(width: 160, height: 36, color: cs.onPrimary)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        hideBalance
                            ? '••••••'
                            : CurrencyFormatter.format(availableCents),
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1),
                      ),
                    ),
                    const Gap(8),
                    IconButton(
                      onPressed: () => ref
                          .read(appSettingsProvider.notifier)
                          .saveBoolSetting('hide_balance', !hideBalance),
                      icon: Icon(
                        hideBalance
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: cs.onPrimary,
                      ),
                      tooltip:
                          hideBalance ? 'Mostrar saldo' : 'Ocultar saldo',
                    ),
                  ],
                ),
              if (!isLoading && initialBalanceCents > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    hideBalance
                        ? 'Saldo anterior: ••••••'
                        : 'Saldo anterior: ${CurrencyFormatter.format(initialBalanceCents)}',
                    style: TextStyle(
                      color: cs.onPrimary.withOpacity(0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const Gap(12),

              // Pills — shimmer individual quando carregando
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: _BalancePill(
                      label: 'Receitas',
                      cents: isLoading ? null : incomeCents,
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF2ECC71),
                      onPrimary: cs.onPrimary,
                      isLoading: isLoading,
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
                      onPrimary: cs.onPrimary,
                      isLoading: isLoading,
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
                      onPrimary: cs.onPrimary,
                      isLoading: isLoading,
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

  Widget _buildTransactionsList(BuildContext context) {
    final month = _formatMonth(_selectedMonth);
    final transactionsAsync = ref.watch(transactionsByMonthProvider(month));

    return transactionsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingScreen),
          child: _EmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Erro ao carregar transações',
          ),
        ),
      ),
      data: (transactions) {
        // Remove imediatamente os itens descartados pelo swipe,
        // sem esperar o provider reconstruir (evita erro do Dismissible)
        final visible = transactions
            .where((t) => t.id == null || !_dismissedIds.contains(t.id))
            .toList();

        final filtered = _selectedFilter == null
            ? visible
            : visible.where((t) => t.type == _selectedFilter).toList();

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
            (context, index) {
              final t = filtered[index];
              return TransactionCard(
                transaction: t,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddTransactionsScreen(transaction: t)),
                ),
                onDeleteWithContext: (ctx) => _handleDeleteTransaction(ctx, t),
                onDelete: () {
                  // Marca como dispensado imediatamente — o Dismissible
                  // precisa que o item suma da árvore no mesmo frame
                  if (t.id != null) {
                    setState(() => _dismissedIds.add(t.id!));
                  }
                  _invalidateAll();
                },
              );
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// FilterBar
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen, vertical: 6),
            child: Row(
              children: [
                // Botões maiores para conforto no celular (44px — área mínima recomendada pelo Material)
                _MonthArrow(
                    icon: Icons.chevron_left_rounded, onTap: onPrevious),
                const Gap(4),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(monthLabel,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                                letterSpacing: -0.2)),
                        if (isFutureMonth) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Text('Projetado',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Gap(4),
                _MonthArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingScreen),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) {
                final f = filters[index];
                final isActive = selectedFilter == f.value;
                return GestureDetector(
                  onTap: () => onFilterChanged(f.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? cs.primary
                          : cs.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(f.icon,
                            size: 13,
                            color: isActive
                                ? cs.onPrimary
                                : cs.onSurface.withOpacity(0.6)),
                        const Gap(5),
                        Text(f.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? cs.onPrimary
                                    : cs.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(6),
          Divider(
              height: 1, thickness: 1, color: cs.onSurface.withOpacity(0.06)),
        ],
      ),
    );
  }
}

// Botão de mês — 44px para área de toque confortável
class _MonthArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MonthArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Icon(icon, size: 22, color: cs.onSurface.withOpacity(0.7)),
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  static const double _height = 87;
  const _StickyFilterDelegate({required this.child});

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_StickyFilterDelegate old) => old.child != child;
}

class _FilterOption {
  final String? value;
  final String label;
  final IconData icon;
  const _FilterOption(
      {required this.value, required this.label, required this.icon});
}

// ---------------------------------------------------------------------------
// Bottom Nav Bar
// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.08))),
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
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.credit_card_outlined,
                  activeIcon: Icons.credit_card_rounded,
                  label: 'Cartões',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Config.',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2)),
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
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    final inactiveColor = cs.onSurface.withOpacity(0.4);

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
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? activeColor : inactiveColor)),
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
  final bool isLoading;

  const _BalancePill({
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
        color: onPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2), shape: BoxShape.circle),
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
                // Shimmer no valor da pill durante loading
                if (isLoading)
                  _Shimmer(width: 44, height: 14, color: onPrimary)
                else
                  Text('R\$ ${_compact(cents ?? 0)}',
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

// Shimmer reutilizável — StatefulWidget leve com um único AnimationController
class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const _Shimmer(
      {required this.width, required this.height, required this.color});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.15, end: 0.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(6),
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gap(24),
        Icon(icon, size: 48, color: cs.onSurface.withOpacity(0.2)),
        const Gap(12),
        Text(message,
            style:
                TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.4))),
        const Gap(24),
      ],
    );
  }
}
