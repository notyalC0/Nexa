import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/core/widgets/app_shimmer.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/cards/screens/card_screen.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/home/widgets/balance_pill.dart';
import 'package:nexa/features/home/widgets/health_score_card.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/settings/screens/settings_screen.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_selection_provider.dart';
import 'package:nexa/features/transactions/screens/add_transactions_screen.dart';
import 'package:nexa/features/transactions/screens/transactions_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Bom dia';
  if (hour >= 12 && hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────

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
          children: const [
            _HomePage(),
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

// ─── _HomePage ────────────────────────────────────────────────────────────────

class _HomePage extends ConsumerWidget {
  const _HomePage();

  static const _selectionTransitionDuration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // select: só rebuilda _HomePage quando muda de sem-seleção para com-seleção
    // (não em cada toggle individual de item)
    final selectionMode = ref.watch(
      selectedTransactionIdsProvider.select((ids) => ids.isNotEmpty),
    );
    final balanceAsync = ref.watch(balanceProvider);
    final hideBalance = ref.watch(appSettingsProvider).maybeWhen(
          data: (s) => s.hideBalance,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: AnimatedSwitcher(
        duration: _selectionTransitionDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: selectionMode
            ? const SizedBox.shrink(key: ValueKey('fab_hidden'))
            : FloatingActionButton.extended(
                key: const ValueKey('fab_visible'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionsScreen()),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 2,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova transação',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          balanceAsync.when(
            loading: () => _HomeHeader(
              isLoading: true,
              hideBalance: hideBalance,
            ),
            error: (_, __) => _HomeHeader(
              isLoading: false,
              hideBalance: hideBalance,
            ),
            data: (b) => _HomeHeader(
              availableCents: b.availableCents,
              projectedCents: b.projectCents,
              incomeCents: b.incomeCents,
              expensesCents: b.expensesCents,
              initialBalanceCents: b.initialBalanceCents,
              isLoading: false,
              hideBalance: hideBalance,
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: _selectionTransitionDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(height: selectionMode ? 0 : 8),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: _selectionTransitionDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: _selectionTransitionDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: selectionMode
                    ? const SizedBox.shrink(key: ValueKey('health_hidden'))
                    : KeyedSubtree(
                        key: const ValueKey('health_visible'),
                        child: ref.watch(healthScoreProvider).when(
                              loading: () => const HealthScoreCard(
                                  score: 0, isLoading: true),
                              error: (_, __) => const HealthScoreCard(score: 0),
                              data: (score) => HealthScoreCard(score: score),
                            ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: _selectionTransitionDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(height: selectionMode ? 6 : 12),
            ),
          ),
          const TransactionFilterBarSliver(),
          const TransactionsListPage(),
          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }
}

// ─── _HomeHeader ──────────────────────────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  final int availableCents;
  final int projectedCents;
  final int incomeCents;
  final int expensesCents;
  final int initialBalanceCents;
  final bool isLoading;
  final bool hideBalance;

  const _HomeHeader({
    this.availableCents = 0,
    this.projectedCents = 0,
    this.incomeCents = 0,
    this.expensesCents = 0,
    this.initialBalanceCents = 0,
    required this.isLoading,
    required this.hideBalance,
  });

  static const _selectionTransitionDuration = Duration(milliseconds: 280);

  void _invalidateAfterDelete(WidgetRef ref) {
    ref.invalidate(transactionsByMonthProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(healthScoreProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(cardLimitDetailsProvider);
  }

  Future<void> _deleteSelected(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // ref.read: lemos os IDs no momento do clique, sem watch
    final selectedIds = ref.read(selectedTransactionIdsProvider);
    final cs = Theme.of(context).colorScheme;
    if (selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusModal),
        ),
        title: Text(
          'Excluir ${selectedIds.length} transações?',
          style: AppTheme.titleStyle(context, fontSize: 16),
        ),
        content: Text(
          'Essa ação não pode ser desfeita.',
          style: AppTheme.subtitleStyle(context, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final id in selectedIds) {
      await DatabaseHelper.instance.deleteTransaction(id);
    }

    ref.read(selectedTransactionIdsProvider.notifier).clear();
    _invalidateAfterDelete(ref);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.snackBar(
        context,
        message: '${selectedIds.length} transações excluídas',
        icon: Icons.delete_outline_rounded,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final greetingText = _greeting();
    // select por count: rebuilda apenas quando o número de selecionados muda
    final selectedCount = ref.watch(
      selectedTransactionIdsProvider.select((ids) => ids.length),
    );
    final selectionMode = selectedCount > 0;
    final titleText =
        '$selectedCount selecionada${selectedCount > 1 ? 's' : ''}';

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 4,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withAlpha(60),
      backgroundColor: cs.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: false,
      leading: AnimatedSwitcher(
        duration: _selectionTransitionDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: selectionMode
            ? IconButton(
                key: const ValueKey('selection_close'),
                tooltip: 'Cancelar seleção',
                onPressed: () =>
                    ref.read(selectedTransactionIdsProvider.notifier).clear(),
                icon: Icon(Icons.close_rounded, color: cs.onPrimary),
              )
            : Padding(
                key: const ValueKey('normal_logo'),
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      title: AnimatedSwitcher(
        duration: _selectionTransitionDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: selectionMode
            ? Text(
                titleText,
                key: ValueKey(titleText),
                style: AppTheme.titleStyle(
                  context,
                  fontSize: 16,
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Text(
                'Nexa',
                key: const ValueKey('normal_title'),
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: _selectionTransitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: selectionMode
              ? IconButton(
                  key: const ValueKey('selection_delete'),
                  tooltip: 'Excluir selecionadas',
                  onPressed: () => _deleteSelected(context, ref),
                  icon: Icon(Icons.delete_outline_rounded, color: cs.onPrimary),
                )
              : const SizedBox.shrink(key: ValueKey('normal_actions_hidden')),
        ),
      ],
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
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingScreen,
            0,
            AppTheme.paddingScreen,
            AppTheme.paddingScreen,
          ),
          child: AnimatedSwitcher(
            duration: _selectionTransitionDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.bottomLeft,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: selectionMode
                ? Align(
                    key: const ValueKey('selection_header_content'),
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$selectedCount',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'Toque na lixeira para excluir em lote',
                            style: TextStyle(
                              color: cs.onPrimary.withAlpha(140),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Align(
                    key: const ValueKey('default_header_content'),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greetingText 👋',
                          style: TextStyle(
                            color: cs.onPrimary.withAlpha(179),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Saldo disponível',
                          style: TextStyle(
                            color: cs.onPrimary.withAlpha(140),
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(3),
                        if (isLoading)
                          AppShimmer(
                              width: 160, height: 40, color: cs.onPrimary)
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  hideBalance
                                      ? 'R\$ \u2022\u2022\u2022\u2022\u2022\u2022'
                                      : CurrencyFormatter.format(
                                          availableCents),
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.5,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const Gap(2),
                              IconButton(
                                onPressed: () => ref
                                    .read(appSettingsProvider.notifier)
                                    .saveBoolSetting(
                                        'hide_balance', !hideBalance),
                                icon: Icon(
                                  hideBalance
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: cs.onPrimary.withAlpha(179),
                                  size: 18,
                                ),
                                tooltip: hideBalance
                                    ? 'Mostrar saldo'
                                    : 'Ocultar saldo',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 30, minHeight: 30),
                              ),
                            ],
                          ),
                        const Gap(14),
                        Row(
                          children: [
                            Flexible(
                              fit: FlexFit.tight,
                              child: BalancePill(
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
                              child: BalancePill(
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
                              child: BalancePill(
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
        ),
      ),
    );
  }
}

// ─── _BottomNavBar ────────────────────────────────────────────────────────────

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
        border: Border(top: BorderSide(color: cs.onSurface.withAlpha(20))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 15),
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
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    final inactiveColor = cs.onSurface.withAlpha(102);

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
              style: AppTheme.metaStyle(
                context,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
