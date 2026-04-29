class CategoryGoal {
  final int? id;
  final int categoryId;
  final int limitCents;

  CategoryGoal({
    this.id,
    required this.categoryId,
    required this.limitCents,
  });

  factory CategoryGoal.fromMap(Map<String, dynamic> map) {
    return CategoryGoal(
      id: map['id'],
      categoryId: map['category_id'],
      limitCents: map['limit_cents'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'limit_cents': limitCents,
    };
  }
}
