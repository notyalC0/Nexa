import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';

class HealthScoreCard extends StatelessWidget {
  final int score; // 0 a 100

  const HealthScoreCard({super.key, required this.score});

  Color _getScoreColor(BuildContext context) {
    if (score >= 80) return const Color(0xFF2ECC71);
    if (score >= 50) return AppTheme.accentColor;
    return Theme.of(context).colorScheme.error;
  }

  String _getScoreLabel() {
    if (score >= 80) return 'Saudável';
    if (score >= 50) return 'Atenção';
    return 'Crítico';
  }

  String _getScoreDescription() {
    if (score >= 80) return 'Suas finanças estão no caminho certo.';
    if (score >= 50) return 'Alguns pontos merecem sua atenção.';
    return 'Suas finanças precisam de cuidado urgente.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoreColor = _getScoreColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Score circular à esquerda ---
          _ScoreCircle(score: score, color: scoreColor),
          const Gap(16),

          // --- Info à direita: Expanded + mainAxisSize.min evita overflow vertical ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: título + badge — Flexible no título evita overflow horizontal
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saúde Financeira',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getScoreLabel(),
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
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const Gap(8),
                Text(
                  _getScoreDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.55),
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

  const _ScoreCircle({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 5,
            backgroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Text(
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
