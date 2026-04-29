class CategoryGoalProgress {
  final String categoryName;
  final String colorHex;
  final String icon;
  final int spentCents;
  final int limitCents;

  const CategoryGoalProgress({
    required this.categoryName,
    required this.colorHex,
    required this.icon,
    required this.spentCents,
    required this.limitCents,
  });

  double get progressRatio {
    if (limitCents <= 0) return 0.0;
    return (spentCents / limitCents).clamp(0.0, double.infinity);
  }

  bool get isOver => spentCents > limitCents;
}
