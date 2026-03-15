import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nexa/core/models/categories.dart';
import 'package:nexa/core/models/transactions.dart';
import '../../../core/database/database_helper.dart';

final categoriesProvider = FutureProvider<List<Categories>>((ref) async {
  return DatabaseHelper.instance.getCategories();
});

final selectedMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

final transactionsByMonthProvider =
    FutureProvider.family<List<Transactions>, String>((ref, month) async {
  return DatabaseHelper.instance.getTransactionsByMonth(month);
});

final transactionsProvider = FutureProvider<List<Transactions>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(transactionsByMonthProvider(month).future);
});
