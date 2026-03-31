import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nexa/features/home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashColor = Color(0xFF091b2e);

  @override
  void initState() {
    super.initState();
    _goHome();
  }

  Future<void> _goHome() async {
    // Aguarda a animação de entrada completar (800ms) + pausa de contemplação (900ms)
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.width * 0.48;

    return Scaffold(
      backgroundColor: _splashColor,
      body: Center(
        child: Image.asset(
          'assets/images/nexa-branding.png',
          width: logoSize,
          fit: BoxFit.contain,
        )
            .animate()
            .fadeIn(
              duration: 700.ms,
              curve: Curves.easeOut,
            )
            .scale(
              begin: const Offset(0.82, 0.82),
              end: const Offset(1.0, 1.0),
              duration: 700.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}
