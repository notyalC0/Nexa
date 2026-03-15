import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import '../../../core/database/database_helper.dart';

final healthScoreProvider = FutureProvider<int>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final db = DatabaseHelper.instance;

  final salaryRaw = await db.getSetting('monthly_salary_cents');

  final salary = int.tryParse(salaryRaw ?? '0') ?? 0;

  final expenses = await db.getTotalExpensesForMonth(month);

  if (salary == 0) return 0;

  final emergencyGoal =
      int.tryParse(await db.getSetting('emergency_goal_cents') ?? '0') ?? 0;
  final emergencyCurrent =
      int.tryParse(await db.getSetting('emergency_current_cents') ?? '0') ?? 0;

  final scoreGastos = (33 - (expenses / salary * 33)).clamp(0, 33);
  final scoreReserva = emergencyGoal == 0
      ? 0
      : (emergencyCurrent / emergencyGoal * 33).clamp(0, 33);
  final scoreCartao = 34;

  final total = (scoreGastos + scoreReserva + scoreCartao).round();

  return total;
});
