class Goal {
  final int? id;
  final String name;
  final int targetAmountCents;
  final int initialAmountCents;
  final String? targetDate;
  final String icon;
  final String colorHex;
  final bool isDefault;
  final bool isDeletable;
  final bool isArchived;
  final String createdAt;
  final String? updatedAt;

  const Goal({
    this.id,
    required this.name,
    required this.targetAmountCents,
    this.initialAmountCents = 0,
    this.targetDate,
    required this.icon,
    required this.colorHex,
    this.isDefault = false,
    this.isDeletable = true,
    this.isArchived = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmountCents: map['target_amount_cents'] as int? ?? 0,
      initialAmountCents: map['initial_amount_cents'] as int? ?? 0,
      targetDate: map['target_date'] as String?,
      icon: map['icon'] as String,
      colorHex: map['color_hex'] as String,
      isDefault: map['is_default'] == 1,
      isDeletable: map['is_deletable'] != 0,
      isArchived: map['is_archived'] == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'target_amount_cents': targetAmountCents,
      'initial_amount_cents': initialAmountCents,
      'target_date': targetDate,
      'icon': icon,
      'color_hex': colorHex,
      'is_default': isDefault ? 1 : 0,
      'is_deletable': isDeletable ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Goal copyWith({
    int? id,
    String? name,
    int? targetAmountCents,
    int? initialAmountCents,
    String? targetDate,
    String? icon,
    String? colorHex,
    bool? isDefault,
    bool? isDeletable,
    bool? isArchived,
    String? createdAt,
    String? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountCents: targetAmountCents ?? this.targetAmountCents,
      initialAmountCents: initialAmountCents ?? this.initialAmountCents,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      isDeletable: isDeletable ?? this.isDeletable,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
