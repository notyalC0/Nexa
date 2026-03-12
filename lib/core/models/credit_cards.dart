class CreditCards {
  final int? id;
  final String name;
  final int totalLimitCents;
  final int closingDay;
  final int dueDay;
  final String? colorHex;
  final String bankKeyword;

  CreditCards({
    this.id,
    required this.name,
    required this.totalLimitCents,
    required this.closingDay,
    required this.dueDay,
    this.colorHex,
    required this.bankKeyword,
  });

  factory CreditCards.fromMap(Map<String, dynamic> map) {
    return CreditCards(
        id: map['id'],
        name: map['name'],
        totalLimitCents: map['total_limit_cents'],
        closingDay: map['closing_day'],
        dueDay: map['due_day'],
        colorHex: map['color_hex'],
        bankKeyword: map['bank_keyword']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'total_limit_cents': totalLimitCents,
      'closing_day': closingDay,
      'due_day': dueDay,
      'color_hex': colorHex,
      'bank_keyword': bankKeyword,
    };
  }
}
