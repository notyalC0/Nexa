import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nexa/core/theme/app_theme.dart';

class HealthScoreCard extends StatelessWidget {
  final int score;
  final bool isLoading;

  const HealthScoreCard(
      {super.key, required this.score, this.isLoading = false});

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
    final cs = Theme.of(context).colorScheme;
    final scoreColor =
        isLoading ? cs.onSurface.withOpacity(0.2) : _getScoreColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score circular — shimmer quando carregando
          _ScoreCircle(score: score, color: scoreColor, isLoading: isLoading),
          const Gap(16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Saúde Financeira',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    // Badge — shimmer quando carregando
                    if (isLoading)
                      _ShimmerBox(
                          width: 60,
                          height: 22,
                          radius: 20,
                          color: cs.onSurface)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_getScoreLabel(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scoreColor)),
                      ),
                  ],
                ),
                const Gap(8),

                // Barra de progresso — cinza quando carregando
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isLoading ? null : score / 100,
                    minHeight: 6,
                    backgroundColor: cs.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const Gap(8),

                // Descrição — shimmer quando carregando
                if (isLoading)
                  _ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 4,
                      color: cs.onSurface)
                else
                  Text(_getScoreDescription(),
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.55),
                          height: 1.4)),
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

  const _ScoreCircle(
      {required this.score, required this.color, this.isLoading = false});

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
            backgroundColor: cs.onSurface.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: isLoading
                ? _ShimmerBox(
                    width: 28, height: 20, radius: 4, color: cs.onSurface)
                : Text('$score',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1)),
          ),
        ],
      ),
    );
  }
}

// Shimmer simples sem dependência externa
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.08, end: 0.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
