import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedTransactionIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void clear() => state = <int>{};

  void add(int id) => state = {...state, id};

  void toggle(int id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  void remove(int id) {
    if (!state.contains(id)) return;
    final next = {...state}..remove(id);
    state = next;
  }
}

/// IDs de transações selecionadas no modo de seleção múltipla.
final selectedTransactionIdsProvider =
    NotifierProvider<SelectedTransactionIdsNotifier, Set<int>>(
  SelectedTransactionIdsNotifier.new,
);
