import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/utils/currency_formatter.dart';
import 'package:nexa/features/cards/screens/card_screen.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/core/widgets/app_shimmer.dart';
import 'package:nexa/features/home/widgets/balance_pill.dart';
import 'package:nexa/features/home/widgets/health_score_card.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/settings/screens/settings_screen.dart';
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

/// Aba principal: header com saldo + health score + lista de transações.
///
/// IMPORTANTE: TransactionFilterBarSliver é inserido DIRETAMENTE no
/// CustomScrollView, fora do SliverMainAxisGroup que vive dentro de
/// TransactionsListPage. Isso evita o erro:
///   "SliverGeometry: layoutExtent exceeds paintExtent"
/// que ocorre quando um SliverPersistentHeader(pinned: true) fica dentro de
/// um SliverMainAxisGroup — o grupo limita o espaço de pintura dos filhos.
class _HomePage extends ConsumerWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceAsync = ref.watch(balanceProvider);
    final hideBalance = ref.watch(appSettingsProvider).maybeWhen(
          data: (s) => s.hideBalance,
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
        label: const Text('Nova transação',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        slivers: [
          // ① Header expansível com saldo
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

          const SliverToBoxAdapter(child: Gap(8)),

          // ② Card de saúde financeira
          SliverToBoxAdapter(
            child: ref.watch(healthScoreProvider).when(
                  loading: () =>
                      const HealthScoreCard(score: 0, isLoading: true),
                  error: (_, __) => const HealthScoreCard(score: 0),
                  data: (score) => HealthScoreCard(score: score),
                ),
          ),

          const SliverToBoxAdapter(child: Gap(12)),

          // ③ Barra de filtros fixada — FORA do SliverMainAxisGroup
          //    TransactionFilterBarSliver lê/escreve transactionsFilterProvider
          const TransactionFilterBarSliver(),

          // ④ Lista de transações (sem header interno)
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final greetingText = _greeting();

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
              colors: [cs.primary, cs.primary.withAlpha(217)],
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
              Text(
                '$greetingText 👋',
                style: TextStyle(
                  color: cs.onPrimary.withAlpha(166),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(2),
              Text(
                'Saldo disponível',
                style: TextStyle(
                  color: cs.onPrimary.withAlpha(166),
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              const Gap(2),

              if (isLoading)
                AppShimmer(width: 160, height: 36, color: cs.onPrimary)
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
                          height: 1,
                        ),
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
                      tooltip: hideBalance ? 'Mostrar saldo' : 'Ocultar saldo',
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
                      color: cs.onPrimary.withAlpha(184),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const Gap(12),

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
