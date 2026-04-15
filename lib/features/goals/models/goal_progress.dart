import 'package:nexa/core/models/goals.dart';

class GoalProgress {
  final Goal goal;
  final int contributedCents;
  final int currentAmountCents;
  final int remainingCents;
  final double averageMonthlyContributionCents;
  final DateTime? estimatedReachDate;

  const GoalProgress({
    required this.goal,
    required this.contributedCents,
    required this.currentAmountCents,
    required this.remainingCents,
    required this.averageMonthlyContributionCents,
    required this.estimatedReachDate,
  });

  bool get isReached => currentAmountCents >= goal.targetAmountCents;

  double get progress {
    if (goal.targetAmountCents <= 0) return 0;
    return currentAmountCents / goal.targetAmountCents;
  }

  bool get hasEstimate =>
      !isReached &&
      remainingCents > 0 &&
      averageMonthlyContributionCents > 0 &&
      estimatedReachDate != null;
}
