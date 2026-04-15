import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/features/goals/models/goal_progress.dart';
import 'package:nexa/features/goals/providers/goals_provider.dart';
import 'package:nexa/features/settings/providers/app_settings_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';

// ─── Modelos ──────────────────────────────────────────────────────────────────

class MonthlyTrend {
  final String month; // "2026-03"
  final int incomeCents;
  final int expensesCents;

  const MonthlyTrend({
    required this.month,
    required this.incomeCents,
    required this.expensesCents,
  });
}

class CategoryExpense {
  final String name;
  final String colorHex;
  final String icon;
  final int totalCents;

  const CategoryExpense({
    required this.name,
    required this.colorHex,
    required this.icon,
    required this.totalCents,
  });
}

class CardExpense {
  final String name;
  final String? colorHex;
  final String bankKeyword;
  final int totalCents;

  const CardExpense({
    required this.name,
    required this.colorHex,
    required this.bankKeyword,
    required this.totalCents,
  });
}

class AnalyticsData {
  final List<MonthlyTrend> trend; // últimos 6 meses
  final List<CategoryExpense> topCategories; // top 6 do mês selecionado
  final List<CardExpense> cardExpenses; // gastos por cartão no mês
  final List<GoalProgress> goals;
  final int currentIncomeCents;
  final int currentExpensesCents;
  final int salaryCents;

  const AnalyticsData({
    required this.trend,
    required this.topCategories,
    required this.cardExpenses,
    required this.goals,
    required this.currentIncomeCents,
    required this.currentExpensesCents,
    required this.salaryCents,
  });

  /// Saldo = receita - despesa do mês selecionado
  int get balanceCents => currentIncomeCents - currentExpensesCents;

  /// Total gasto em cartões de crédito
  int get totalCardExpensesCents =>
      cardExpenses.fold(0, (s, c) => s + c.totalCents);

  /// Total gasto em débito/dinheiro
  int get cashExpensesCents => (currentExpensesCents - totalCardExpensesCents)
      .clamp(0, currentExpensesCents);

  /// Percentual gasto em relação ao salário (0.0–1.0+)
  double get expenseToSalaryRatio =>
      salaryCents == 0 ? 0 : currentExpensesCents / salaryCents;

  bool get hasSalary => salaryCents > 0;
  bool get hasGoals => goals.isNotEmpty;
  bool get hasCardExpenses => cardExpenses.isNotEmpty;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final currentMonth = ref.watch(selectedMonthProvider);

  // Assiste transações para reconstruir quando houver alterações
  await ref.watch(transactionsProvider.future);
  final goals = await ref.watch(goalsProvider.future);

  final db = DatabaseHelper.instance;
  final defaultGoal = goals.where((goal) => goal.goal.isDefault).firstOrNull;
  final preservedGoalId = defaultGoal?.goal.id;

  // ── Tendência: últimos 6 meses (sempre relativo ao mês atual real) ──────
  final now = DateTime.now();
  final trend = <MonthlyTrend>[];
  for (int i = 5; i >= 0; i--) {
    final dt = DateTime(now.year, now.month - i, 1);
    final month = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    final income = await db.getTotalIncomeForMonth(month);
    final expenses = await db.getTotalExpensesForMonth(
      month,
      neutralizeGoalTransactions: true,
      preservedGoalId: preservedGoalId,
    );
    trend.add(MonthlyTrend(
      month: month,
      incomeCents: income,
      expensesCents: expenses,
    ));
  }

  // ── Gastos por categoria no mês selecionado ───────────────────────────
  final transactions = await db.getTransactionsByEffectiveMonth(currentMonth);
  final categories = await db.getCategories();
  final categoryMap = {for (final c in categories) c.id: c};

  final totals = <int, int>{};
  for (final t in transactions) {
    if (t.type == 'expense' && t.status == 'confirmed') {
      if (t.goalId != null && t.goalId != preservedGoalId) continue;
      totals[t.categoryID] = (totals[t.categoryID] ?? 0) + t.amountCents;
    }
  }

  final topCategories = totals.entries
      .map((e) {
        final cat = categoryMap[e.key];
        if (cat == null) return null;
        return CategoryExpense(
          name: cat.name,
          colorHex: cat.colorHex,
          icon: cat.icon,
          totalCents: e.value,
        );
      })
      .whereType<CategoryExpense>()
      .toList()
    ..sort((a, b) => b.totalCents.compareTo(a.totalCents));

  // ── Gastos por cartão no mês selecionado ─────────────────────────────
  final cards = await db.getCreditCards();
  final cardMap = {for (final c in cards) c.id: c};
  final cardTotals = <int, int>{};
  for (final t in transactions) {
    if (t.type == 'expense' &&
        t.status == 'confirmed' &&
        t.creditCardsId != null) {
      if (t.goalId != null && t.goalId != preservedGoalId) continue;
      cardTotals[t.creditCardsId!] =
          (cardTotals[t.creditCardsId!] ?? 0) + t.amountCents;
    }
  }
  final cardExpenses = cardTotals.entries
      .map((e) {
        final card = cardMap[e.key];
        if (card == null) return null;
        return CardExpense(
          name: card.name,
          colorHex: card.colorHex,
          bankKeyword: card.bankKeyword,
          totalCents: e.value,
        );
      })
      .whereType<CardExpense>()
      .toList()
    ..sort((a, b) => b.totalCents.compareTo(a.totalCents));

  // ── Resumo do mês selecionado ─────────────────────────────────────────
  final currentIncome = await db.getTotalIncomeForMonth(currentMonth);
  final currentExpenses = await db.getTotalExpensesForMonth(
    currentMonth,
    neutralizeGoalTransactions: true,
    preservedGoalId: preservedGoalId,
  );

  // ── Settings — assistidas para reagir a mudanças ─────────────────────
  final settingsAsync = await ref.watch(appSettingsProvider.future);
  final salary = settingsAsync.salaryCents;

  return AnalyticsData(
    trend: trend,
    topCategories: topCategories.take(6).toList(),
    cardExpenses: cardExpenses,
    goals: goals,
    currentIncomeCents: currentIncome,
    currentExpensesCents: currentExpenses,
    salaryCents: salary,
  );
});
