import 'package:flutter/material.dart';

/// Widget de shimmer (efeito de carregamento pulsante).
///
/// Usado em toda a app enquanto dados estão sendo buscados do banco.
/// Extraído para arquivo próprio pois é reutilizado em vários widgets.
///
/// Exemplo de uso:
/// ```dart
/// AppShimmer(width: 120, height: 20, color: Colors.white)
/// ```
class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final double borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.borderRadius = 6,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _anim = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
          color: widget.color.withAlpha((_anim.value * 255).round()),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
