import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';

class BalanceSummary {
  final int availableCents;
  final int projectCents;
  final int incomeCents;
  final int expensesCents;

  BalanceSummary({
    required this.availableCents,
    required this.projectCents,
    required this.incomeCents,
    required this.expensesCents,
  });
}

final balanceProvider = FutureProvider<BalanceSummary>((ref) async {
  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final db = DatabaseHelper.instance;

  final income = await db.getTotalIncomeForMonth(month);
  final expenses = await db.getTotalExpensesForMonth(month);
  final available = income - expenses;
  final project = await db.getProjectedBalanceForMonth(month);

  return BalanceSummary(
    availableCents: available,
    projectCents: project,
    incomeCents: income,
    expensesCents: expenses,
  );
});
