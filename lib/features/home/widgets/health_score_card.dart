import 'package:flutter/material.dart';
import 'package:nexa/core/theme/app_theme.dart';

class HealthScoreCard extends StatelessWidget {
  final int score; // 0 a 100

  const HealthScoreCard({super.key, required this.score});

  // Retorna a cor certa baseada no score
  Color _getScoreColor() {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 50) return AppTheme.accentColor;
    return AppTheme.errorColor;
  }

  // Retorna o label certo
  String _getScoreLabel() {
    if (score >= 80) return 'Saudável';
    if (score >= 50) return 'Atenção';
    return 'Crítico';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingScreen),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saúde Financeira',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _getScoreLabel(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100, // score é 0-100, o value precisa ser 0.0-1.0
              minHeight: 20,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Score: $score / 100',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
