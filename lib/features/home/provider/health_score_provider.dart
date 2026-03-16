import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa/features/cards/providers/cards_provider.dart';
import 'package:nexa/features/transactions/providers/transactions_provider.dart';
import '../../../core/database/database_helper.dart';

final healthScoreProvider = FutureProvider<int>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final db = DatabaseHelper.instance;

  // Salário base
  final salary = int.tryParse(
        await db.getSetting('monthly_salary_cents') ?? '0',
      ) ?? 0;

  if (salary == 0) return 0;

  // --- Score 1: Gastos vs salário (0–33) ---
  final expenses = await db.getTotalExpensesForMonth(month);
  final scoreGastos = (33.0 - (expenses / salary * 33.0)).clamp(0.0, 33.0);

  // --- Score 2: Reserva de emergência (0–33) ---
  final emergencyGoal = int.tryParse(
        await db.getSetting('emergency_goal_cents') ?? '0',
      ) ?? 0;
  final emergencyCurrent = int.tryParse(
        await db.getSetting('emergency_current_cents') ?? '0',
      ) ?? 0;

  final scoreReserva = emergencyGoal == 0
      ? 0.0
      : (emergencyCurrent / emergencyGoal * 33.0).clamp(0.0, 33.0);

  // --- Score 3: Uso total dos cartões (0–34) ---
  // Busca todos os cartões e agrega limite/uso via cardLimitDetailsProvider
  final cards = await ref.watch(creditCardProvider.future);

  double scoreCartao = 34.0; // padrão: sem cartão não penaliza

  if (cards.isNotEmpty) {
    // Busca CardLimitDetails de cada cartão em paralelo
    final details = await Future.wait(
      cards.map((c) => ref.watch(cardLimitDetailsProvider(c.id!).future)),
    );

    final totalLimit = details.fold<int>(0, (sum, d) => sum + d.dynamicLimitCents);
    final totalUsed  = details.fold<int>(0, (sum, d) => sum + d.usedCents);

    scoreCartao = totalLimit == 0
        ? 34.0
        : ((1.0 - totalUsed / totalLimit) * 34.0).clamp(0.0, 34.0);
  }

  final total = (scoreGastos + scoreReserva + scoreCartao).round().clamp(0, 100);

  return total;
});
