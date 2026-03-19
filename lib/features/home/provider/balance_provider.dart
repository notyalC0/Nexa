import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import '../../../core/database/database_helper.dart';

class BalanceSummary {
  final int initialBalanceCents;
  final int availableCents;
  final int projectCents;
  final int incomeCents;
  final int expensesCents;

  BalanceSummary({
    required this.initialBalanceCents,
    required this.availableCents,
    required this.projectCents,
    required this.incomeCents,
    required this.expensesCents,
  });
}

final balanceProvider = FutureProvider<BalanceSummary>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final db = DatabaseHelper.instance;

  final income = await db.getTotalIncomeForMonth(month);
  final expenses = await db.getTotalExpensesForMonth(month);
  final initialBalance = await db.getCarryOverForMonth(month);
  final available = initialBalance + income - expenses;
  final project = await db.getProjectedBalanceForMonth(month);

  return BalanceSummary(
    initialBalanceCents: initialBalance,
    availableCents: available,
    projectCents: project,
    incomeCents: income,
    expensesCents: expenses,
  );
});
