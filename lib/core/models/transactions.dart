class Transactions {
  final int? id;
  final int amountCents;
  final String type;
  final String status;
  final String? description;
  final String date;
  final int categoryID;
  final int? creditCardsId;
  final int? installmentTotal;
  final int? installmentCurrent;
  final String? installmentGroupId;
  final bool isRecurring;
  final String? recurringId;
  final int? parentId;
  final String? note;
  final bool createdFromNotification;
  final String? createdAt;

  Transactions(
      {this.id,
      required this.amountCents,
      required this.type,
      required this.status,
      this.description,
      required this.date,
      required this.categoryID,
      this.creditCardsId,
      this.installmentTotal,
      this.installmentCurrent,
      this.installmentGroupId,
      required this.isRecurring,
      this.recurringId,
      this.parentId,
      this.note,
      required this.createdFromNotification,
      this.createdAt});

  factory Transactions.fromMap(Map<String, dynamic> map) {
    return Transactions(
        id: map['id'],
        amountCents: map['amount_cents'],
        type: map['type'],
        status: map['status'],
        description: map['description'],
        date: map['date'],
        categoryID: map['category_id'],
        creditCardsId: map['credit_cards_id'],
        installmentTotal: map['installment_total'],
        installmentCurrent: map['installment_current'],
        installmentGroupId: map['installment_group_id'],
        isRecurring: map['is_recurring'] == 1,
        recurringId: map['recurring_id'],
        parentId: map['parent_id'],
        note: map['note'],
        createdFromNotification: map['created_from_notification'] == 1,
        createdAt: map['created_at']);
  }

  Map<String, dynamic> toMap() {
    return {
      'amount_cents': amountCents,
      'type': type,
      'status': status,
      'description': description,
      'date': date,
      'category_id': categoryID,
      'credit_cards_id': creditCardsId,
      'installment_total': installmentTotal,
      'installment_current': installmentCurrent,
      'installment_group_id': installmentGroupId,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_id': recurringId,
      'parent_id': parentId,
      'note': note,
      'created_from_notification': createdFromNotification ? 1 : 0,
      'created_at': createdAt
    };
  }
}
