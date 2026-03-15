import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/models/credit_cards.dart';
import 'package:nexa/features/home/provider/balance_provider.dart';
import '../../../core/database/database_helper.dart';

class CardLimitDetails {
  final int usedCents;
  final int dynamicLimitCents;

  const CardLimitDetails({
    required this.usedCents,
    required this.dynamicLimitCents,
  });

  int get availableCents =>
      (dynamicLimitCents - usedCents).clamp(0, dynamicLimitCents);
  double get usedPercent =>
      dynamicLimitCents == 0 ? 0 : (usedCents / dynamicLimitCents).clamp(0, 1);
}

final creditCardProvider = FutureProvider<List<CreditCards>>((ref) async {
  return DatabaseHelper.instance.getCreditCards();
});

final cardLimitDetailsProvider =
    FutureProvider.family<CardLimitDetails, int>((ref, cardId) async {
  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final db = DatabaseHelper.instance;

  final cards = await ref.watch(creditCardProvider.future);
  final cardIndex = cards.indexWhere((item) => item.id == cardId);
  final card = cardIndex >= 0 ? cards[cardIndex] : null;
  final usedCents = await db.getCardUsedLimitForMonth(cardId, month);
  final dynamicLimitCents = card?.totalLimitCents ?? 0;

  return CardLimitDetails(
    usedCents: usedCents,
    dynamicLimitCents: dynamicLimitCents,
  );
});
