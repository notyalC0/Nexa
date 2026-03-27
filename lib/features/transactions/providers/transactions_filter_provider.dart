// lib/features/transactions/providers/transactions_filter_provider.dart
//
// Provider que eleva o estado de mês/filtro do TransactionsListPage
// para que o SliverPersistentHeader possa ser posicionado fora do
// SliverMainAxisGroup no _HomePage, corrigindo o erro de SliverGeometry.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionsFilterState {
  final DateTime selectedMonth;
  final DateTime selectedMonth;
  final String? selectedFilter;

  const TransactionsFilterState({
    required this.selectedMonth,
    this.selectedFilter,
  });

  TransactionsFilterState copyWith({
    DateTime? selectedMonth,
    String? selectedFilter,
    bool clearFilter = false,
  }) {
    return TransactionsFilterState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedFilter:
          clearFilter ? null : (selectedFilter ?? this.selectedFilter),
    );
  }
}

class TransactionsFilterNotifier
    extends StateNotifier<TransactionsFilterState> {
  TransactionsFilterNotifier()
      : super(TransactionsFilterState(
          selectedMonth: DateTime(
            DateTime.now().year,
            DateTime.now().month,
          ),
        ));

  void previousMonth() {
    final m = state.selectedMonth;
    state = state.copyWith(selectedMonth: DateTime(m.year, m.month - 1));
  }

  void nextMonth() {
    final m = state.selectedMonth;
    state = state.copyWith(selectedMonth: DateTime(m.year, m.month + 1));
  }

  void setFilter(String? filter) {
    if (filter == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(selectedFilter: filter);
    }
  }
}

final transactionsFilterProvider = StateNotifierProvider<
    TransactionsFilterNotifier, TransactionsFilterState>(
  (ref) => TransactionsFilterNotifier(),
);
