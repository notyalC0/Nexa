import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/models/transactions.dart';
import '../../../core/database/database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CORRIGIDO: removido "import 'package:flutter_riverpod/legacy.dart'"
//
// No Riverpod 3.x o StateProvider ainda existe, mas a importação do legacy
// foi criada para ajudar na migração do v1→v2. No v3 ela não é mais necessária
// e vai ser removida em versões futuras. Tudo vem de 'flutter_riverpod'.
// ─────────────────────────────────────────────────────────────────────────────

/// Provider que lista todas as categorias disponíveis.
/// Usado nos dropdowns de categoria na tela de adicionar transação.
final categoriesProvider = FutureProvider<List<Categories>>((ref) async {
  return DatabaseHelper.instance.getCategories();
});

/// Mês atualmente selecionado no filtro da home (formato: "2025-03").
/// StateProvider é o tipo mais simples do Riverpod — armazena um único valor
/// e notifica os widgets que o observam quando ele muda.
final selectedMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

/// Transações filtradas por mês.
///
/// Por que FutureProvider.family?
/// O "family" permite passar um parâmetro (o mês) para o provider.
/// Cada mês diferente cria uma instância separada e cacheada do provider.
/// Ex: transactionsByMonthProvider("2025-03") é diferente de
///     transactionsByMonthProvider("2025-04")
final transactionsByMonthProvider =
    FutureProvider.family<List<Transactions>, String>((ref, month) async {
  return DatabaseHelper.instance.getTransactionsByMonth(month);
});

/// Alias conveniente que já lê o mês do selectedMonthProvider.
/// Usado em providers que precisam das transações mas não querem
/// receber o mês explicitamente.
final transactionsProvider = FutureProvider<List<Transactions>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionsByMonthProvider(month).future);
});
