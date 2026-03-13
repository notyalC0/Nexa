import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/features/home/widgets/health_score_card.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import 'package:nexa/features/transactions/widgets/transaction_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          const SliverToBoxAdapter(
            child: HealthScoreCard(
              score: 75,
            ), // health card
          ),
          _buildTransactionsList(ref),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(child: Text('Erro: $err')),
      ),
      data: (transactions) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => TransactionCard(
            transaction: transactions[index],
          ),
          childCount: transactions.length,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.all(20.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Disponível',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 24,
                  ),
                ),
                const Text(
                  'R\$ 5.000,00',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
              ]),
        ),
      ),
    );
  }
}
