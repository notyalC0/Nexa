import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/core/models/credit_cards.dart';
import '../../../core/database/database_helper.dart';

final creditCardProvider = FutureProvider<List<CreditCards>>((ref) async {
  return DatabaseHelper.instance.getCreditCards();
});
