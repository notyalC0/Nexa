import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/core/models/transactions.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/widgets/app_empty_state.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import 'package:nexa/features/home/provider/health_score_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_filter_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_selection_provider.dart';
import 'package:nexa/features/transactions/screens/add_transactions_screen.dart';
import 'package:nexa/features/transactions/widgets/transaction_card.dart';
import 'package:nexa/features/transactions/widgets/transaction_filter_bar.dart';

// Filtros disponíveis — definidos aqui pois são específicos desta tela
const _filters = [
  FilterOption(value: null, label: 'Todos', icon: Icons.list_rounded),
  FilterOption(
      value: 'income', label: 'Receitas', icon: Icons.arrow_upward_rounded),
  FilterOption(
      value: 'expense', label: 'Despesas', icon: Icons.arrow_downward_rounded),
];

String _formatMonth(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String _monthLabel(DateTime date) {
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
  final label = months[date.month - 1];
  if (date.year != DateTime.now().year) return '$label ${date.year}';
  return label;
}

bool _isFutureMonth(DateTime date) {
  final now = DateTime.now();
  return date.isAfter(DateTime(now.year, now.month));
}

// ─── TransactionFilterBarSliver ───────────────────────────────────────────────
//
// Widget que constrói o SliverPersistentHeader da barra de filtros.
// Fica FORA do SliverMainAxisGroup (renderizado pelo _HomePage) para evitar
// o erro: SliverGeometry "layoutExtent" exceeds "paintExtent".

class TransactionFilterBarSliver extends ConsumerWidget {
  const TransactionFilterBarSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionsFilterProvider);
    final notifier = ref.read(transactionsFilterProvider.notifier);

    return SliverPersistentHeader(
      floating: true,
      delegate: StickyFilterDelegate(
        child: TransactionFilterBar(
          monthLabel: _monthLabel(filter.selectedMonth),
          isFutureMonth: _isFutureMonth(filter.selectedMonth),
          onPrevious: () {
            ref.read(selectedTransactionIdsProvider.notifier).clear();
            notifier.previousMonth();
          },
          onNext: () {
            ref.read(selectedTransactionIdsProvider.notifier).clear();
            notifier.nextMonth();
          },
          selectedFilter: filter.selectedFilter,
          filters: _filters,
          onFilterChanged: (value) {
            ref.read(selectedTransactionIdsProvider.notifier).clear();
            notifier.setFilter(value);
          },
        ),
      ),
    );
  }
}

// ─── TransactionsListPage ─────────────────────────────────────────────────────
//
// Retorna apenas a lista de transações (SliverMainAxisGroup sem header fixo).
// O header de filtros foi movido para TransactionFilterBarSliver, que é
// inserido diretamente no CustomScrollView do _HomePage.

class TransactionsListPage extends ConsumerStatefulWidget {
  const TransactionsListPage({super.key});

  @override
  ConsumerState<TransactionsListPage> createState() =>
      _TransactionsListPageState();
}

class _TransactionsListPageState extends ConsumerState<TransactionsListPage> {
  // IDs que foram descartados pelo swipe mas o provider ainda não atualizou.
  // Evita: "A dismissed Dismissible widget is still part of the tree"
  final Set<int> _dismissedIds = {};

  // Chave para SliverAnimatedList
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  // Última lista filtrada renderizada — usada para animar remoções
  List<Transactions> _currentFiltered = [];

  /// Invalida todos os providers relacionados após uma alteração.
  void _invalidateAll() {
    ref.invalidate(transactionsByMonthProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(healthScoreProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(cardLimitDetailsProvider);
  }

  /// Remove um item da lista com animação de saída.
  void _animateRemoveAt(int index, Transactions t) {
    if (index < 0 || index >= _currentFiltered.length) return;
    _currentFiltered.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedItem(t, animation),
      duration: const Duration(milliseconds: 340),
    );
  }

  Widget _buildRemovedItem(Transactions t, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: TransactionCard(transaction: t),
      ),
    );
  }

  /// Sincroniza _currentFiltered com a nova lista, animando inserções e remoções.
  void _syncList(List<Transactions> newFiltered) {
    final oldIds = _currentFiltered.map((t) => t.id).toList();
    final newIds = newFiltered.map((t) => t.id).toList();

    // Detecta remoções (itens no old que não estão no new)
    for (int i = oldIds.length - 1; i >= 0; i--) {
      if (!newIds.contains(oldIds[i])) {
        final removed = _currentFiltered.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedItem(removed, animation),
          duration: const Duration(milliseconds: 340),
        );
      }
    }

    // Detecta inserções (itens no new que não estão nos oldIds atualizados)
    final currentIds = _currentFiltered.map((t) => t.id).toList();
    for (int i = 0; i < newFiltered.length; i++) {
      if (!currentIds.contains(newFiltered[i].id)) {
        _currentFiltered.insert(i, newFiltered[i]);
        _listKey.currentState
            ?.insertItem(i, duration: const Duration(milliseconds: 280));
      }
    }

    // Atualiza dados existentes sem animar
    for (int i = 0; i < _currentFiltered.length; i++) {
      final matchIdx =
          newFiltered.indexWhere((t) => t.id == _currentFiltered[i].id);
      if (matchIdx >= 0) {
        _currentFiltered[i] = newFiltered[matchIdx];
      }
    }
  }

  // ─── DELETE DIALOGS ────────────────────────────────────────────────────────

  Future<bool> _confirmDeleteSingle(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        title: Row(children: [
          _errorIconContainer(cs),
          const Gap(12),
          Text('Excluir transação',
              style: AppTheme.titleStyle(context, fontSize: 16)),
        ]),
        content: Text(
          'Tem certeza que deseja excluir esta transação? Esta ação não pode ser desfeita.',
          style: AppTheme.subtitleStyle(
            context,
            fontSize: 14,
            color: cs.onSurface.withAlpha(178),
            height: 1.4,
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          _cancelButton(ctx, cs),
          _deleteButton(ctx, cs),
        ],
      ),
    );
    return result == true;
  }

  Future<bool> _handleDeleteTransaction(
      BuildContext context, Transactions transaction) async {
    final cs = Theme.of(context).colorScheme;

    // Caso 1: Transação recorrente
    if (transaction.isRecurring) {
      final option = await showDialog<String>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
          backgroundColor: cs.surface,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Icon(Icons.repeat_rounded, color: cs.error, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Text('Transação recorrente',
                  style: AppTheme.titleStyle(context, fontSize: 16)),
            ),
          ]),
          content: Text(
            'Deseja deletar apenas esta ou todas as parcelas futuras?',
            style: AppTheme.subtitleStyle(
              context,
              fontSize: 14,
              color: cs.onSurface.withAlpha(178),
              height: 1.4,
            ),
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
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'current'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withAlpha(127)),
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
            ]),
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

    // Caso 2: Compra parcelada
    final canDeleteGroup = transaction.creditCardsId != null &&
        (transaction.installmentTotal ?? 1) > 1 &&
        (transaction.installmentGroupId?.isNotEmpty ?? false);

    if (!canDeleteGroup) {
      final confirmed = await _confirmDeleteSingle(context);
      if (!confirmed) return false;
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
      return true;
    }

    final option = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModal)),
        backgroundColor: cs.surface,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.error.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Icon(Icons.layers_outlined, color: cs.error, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Text('Compra parcelada',
                style: AppTheme.titleStyle(context, fontSize: 16)),
          ),
        ]),
        content: Text(
          'Deseja excluir somente esta parcela ou todas as parcelas desta compra?',
          style: AppTheme.subtitleStyle(
            context,
            fontSize: 14,
            color: cs.onSurface.withAlpha(178),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                  foregroundColor: cs.onSurface.withAlpha(127)),
              child: const Text('Cancelar'),
            ),
          ),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'current'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withAlpha(127)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
                ),
                child: const Text('Todas',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ]),
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

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Lê o mês selecionado do provider compartilhado
    final filter = ref.watch(transactionsFilterProvider);
    final selectedIds = ref.watch(selectedTransactionIdsProvider);
    final selectionMode = selectedIds.isNotEmpty;
    final month = _formatMonth(filter.selectedMonth);
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
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Erro ao carregar transações',
          ),
        ),
      ),
      data: (transactions) {
        final visible = transactions
            .where((t) => t.id == null || !_dismissedIds.contains(t.id))
            .toList();

        final filtered = filter.selectedFilter == null
            ? visible
            : visible.where((t) => t.type == filter.selectedFilter).toList();

        if (filtered.isEmpty) {
          // Limpa a lista animada quando a filtragem resulta em vazio
          _currentFiltered = [];
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingScreen),
              child: AppEmptyState(
                icon: filter.selectedFilter != null
                    ? Icons.filter_list_off_rounded
                    : Icons.receipt_long_outlined,
                message: filter.selectedFilter != null
                    ? 'Nenhuma transação com este filtro'
                    : 'Nenhuma transação em ${_monthLabel(filter.selectedMonth)}',
              ),
            ),
          );
        }

        // Sincroniza a lista animada com os dados atualizados
        if (_currentFiltered.isEmpty && filtered.isNotEmpty) {
          // Primeira carga ou retorno do vazio — reset completo
          _currentFiltered = List.of(filtered);
        } else if (_currentFiltered.isNotEmpty) {
          // Só anima se os IDs mudaram de fato (evita chamadas desnecessárias)
          final currIds = _currentFiltered.map((t) => t.id).toSet();
          final newIds = filtered.map((t) => t.id).toSet();
          final hasChanges =
              currIds.length != newIds.length || !currIds.containsAll(newIds);
          if (hasChanges) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncList(filtered);
            });
          }
        }

        return SliverAnimatedList(
          key: _listKey,
          initialItemCount: _currentFiltered.length,
          itemBuilder: (context, index, animation) {
            if (index >= _currentFiltered.length) {
              return const SizedBox.shrink();
            }
            final t = _currentFiltered[index];
            final txId = t.id;

            return SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: TransactionCard(
                  transaction: t,
                  selectionMode: selectionMode,
                  isSelected: txId != null && selectedIds.contains(txId),
                  onActivateSelection: txId == null
                      ? null
                      : () {
                          ref
                              .read(selectedTransactionIdsProvider.notifier)
                              .add(txId);
                        },
                  onToggleSelection: txId == null
                      ? null
                      : () {
                          ref
                              .read(selectedTransactionIdsProvider.notifier)
                              .toggle(txId);
                        },
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddTransactionsScreen(transaction: t)),
                  ),
                  onDeleteWithContext: (ctx) =>
                      _handleDeleteTransaction(ctx, t),
                  onDelete: () {
                    if (t.id != null) {
                      setState(() => _dismissedIds.add(t.id!));
                      ref
                          .read(selectedTransactionIdsProvider.notifier)
                          .remove(t.id!);
                    }
                    // Anima a remoção
                    final removeIdx =
                        _currentFiltered.indexWhere((tx) => tx.id == t.id);
                    if (removeIdx >= 0) {
                      _animateRemoveAt(removeIdx, t);
                    }
                    _invalidateAll();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── HELPERS DE UI ─────────────────────────────────────────────────────────

  Widget _errorIconContainer(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.error.withAlpha(25),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
      );

  Widget _cancelButton(BuildContext ctx, ColorScheme cs) => TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurface.withAlpha(153),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: const Text('Cancelar',
            style: TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _deleteButton(BuildContext ctx, ColorScheme cs) => ElevatedButton(
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
      );
}
