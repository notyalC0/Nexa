import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/features/home/widgets/health_score_card.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/screens/add_transactions_screen.dart';
import '../../transactions/widgets/transaction_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: CustomScrollView(
          slivers: [
            _buildHeader(context),
            const SliverToBoxAdapter(child: Gap(8)),
            SliverToBoxAdapter(
              child: HealthScoreCard(score: 75),
            ),
            _buildSectionTitle(context, 'Transações recentes'),
            _buildTransactionsList(ref, context),
            const SliverToBoxAdapter(child: Gap(100)),
          ],
        ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      // expandedHeight maior garante espaço suficiente para o conteúdo do header
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
          // padding top = 0; mainAxisAlignment.end cuida do posicionamento
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
                'Bom dia 👋',
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(2),
              Text(
                'Saldo disponível',
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.65),
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              const Gap(2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '5.000,00',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  _BalancePill(
                    label: 'Receitas',
                    value: 'R\$ 8.200',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF2ECC71),
                    onPrimary: colorScheme.onPrimary,
                  ),
                  const Gap(12),
                  _BalancePill(
                    label: 'Despesas',
                    value: 'R\$ 3.200',
                    icon: Icons.arrow_downward_rounded,
                    color: Colors.redAccent,
                    onPrimary: colorScheme.onPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.paddingScreen,
          8,
          AppTheme.paddingScreen,
          10,
        ),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(WidgetRef ref, BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

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
        if (transactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingScreen),
              child: _EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Nenhuma transação ainda',
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => TransactionCard(
              transaction: transactions[index],
            ),
            childCount: transactions.length,
          ),
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTransactionsScreen()),
      ),
      backgroundColor: colorScheme.secondary,
      foregroundColor: colorScheme.onSecondary,
      elevation: 2,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Nova transação',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// --- Widgets internos ---

class _BalancePill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color onPrimary;

  const _BalancePill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Icon(icon, size: 12, color: color),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: onPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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
        Icon(
          icon,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
        const Gap(12),
        Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 14,
          ),
        ),
        const Gap(24),
      ],
    );
  }
}
