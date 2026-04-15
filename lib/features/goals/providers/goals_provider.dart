import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/database/database_helper.dart';
import 'package:nexa/features/goals/models/goal_progress.dart';

final goalsProvider = FutureProvider<List<GoalProgress>>((ref) async {
  final db = DatabaseHelper.instance;
  final goals = await db.getGoals();

  final progressList = await Future.wait(
    goals.map((goal) async {
      final contributions = await db.getTransactionsForGoal(
        goal.id!,
        confirmedOnly: true,
      );

      final contributedCents =
          contributions.fold<int>(0, (sum, tx) => sum + tx.amountCents);
      final currentAmountCents = goal.initialAmountCents + contributedCents;
      final remainingCents =
          (goal.targetAmountCents - currentAmountCents).clamp(0, 1 << 62);

      final monthlyTotals = <String, int>{};
      for (final tx in contributions) {
        final monthKey = tx.effectiveDate.substring(0, 7);
        monthlyTotals[monthKey] =
            (monthlyTotals[monthKey] ?? 0) + tx.amountCents;
      }

      final averageMonthlyContributionCents =
          monthlyTotals.isEmpty ? 0.0 : contributedCents / monthlyTotals.length;

      DateTime? estimatedReachDate;
      if (remainingCents > 0 && averageMonthlyContributionCents > 0) {
        final monthsNeeded =
            (remainingCents / averageMonthlyContributionCents).ceil();
        final now = DateTime.now();
        estimatedReachDate = DateTime(now.year, now.month + monthsNeeded, 1);
      }

      return GoalProgress(
        goal: goal,
        contributedCents: contributedCents,
        currentAmountCents: currentAmountCents,
        remainingCents: remainingCents,
        averageMonthlyContributionCents: averageMonthlyContributionCents,
        estimatedReachDate: estimatedReachDate,
      );
    }),
  );

  return progressList
    ..sort((a, b) {
      if (a.goal.isDefault != b.goal.isDefault) {
        return a.goal.isDefault ? -1 : 1;
      }
      return a.goal.createdAt.compareTo(b.goal.createdAt);
    });
});

final defaultGoalProgressProvider = FutureProvider<GoalProgress?>((ref) async {
  final goals = await ref.watch(goalsProvider.future);
  for (final goal in goals) {
    if (goal.goal.isDefault) return goal;
  }
  return null;
});
