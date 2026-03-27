import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';
import 'package:nexa/core/widgets/app_shimmer.dart';

/// Card de saúde financeira exibido na home.
///
/// Calcula uma pontuação de 0–100 baseada em:
///   - Proporção de gastos vs salário
///   - Reserva de emergência
///   - Uso do limite dos cartões
class HealthScoreCard extends StatelessWidget {
  final int score;
  final bool isLoading;

  const HealthScoreCard({
    super.key,
    required this.score,
    this.isLoading = false,
  });

  Color _scoreColor(BuildContext context) {
    if (score >= 80) return const Color(0xFF2ECC71); // verde
    if (score >= 50) return AppTheme.accentColor; // amarelo/gold
    return Theme.of(context).colorScheme.error; // vermelho
  }

  String _scoreLabel() {
    if (score >= 80) return 'Saudável';
    if (score >= 50) return 'Atenção';
    return 'Crítico';
  }

  String _scoreDescription() {
    if (score >= 80) return 'Suas finanças estão no caminho certo.';
    if (score >= 50) return 'Alguns pontos merecem sua atenção.';
    return 'Suas finanças precisam de cuidado urgente.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scoreColor =
        isLoading ? cs.onSurface.withAlpha(51) : _scoreColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cs.onSurface.withAlpha(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ScoreCircle(score: score, color: scoreColor, isLoading: isLoading),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título + badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saúde Financeira',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoading)
                      AppShimmer(
                          width: 60,
                          height: 22,
                          borderRadius: 20,
                          color: cs.onSurface)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scoreColor.withAlpha(31),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _scoreLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(8),

                // Barra de progresso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isLoading ? null : score / 100,
                    minHeight: 6,
                    backgroundColor: cs.onSurface.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const Gap(8),

                // Descrição
                if (isLoading)
                  AppShimmer(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 4,
                      color: cs.onSurface)
                else
                  Text(
                    _scoreDescription(),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(140),
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int score;
  final Color color;
  final bool isLoading;

  const _ScoreCircle({
    required this.score,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: isLoading ? null : score / 100,
            strokeWidth: 5,
            backgroundColor: cs.onSurface.withAlpha(20),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: isLoading
                ? AppShimmer(
                    width: 28, height: 20, borderRadius: 4, color: cs.onSurface)
                : Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
