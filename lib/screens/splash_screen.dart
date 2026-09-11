import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: CobaltColors.background,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: const _SplashContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: CobaltColors.cobalt,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: CobaltColors.cobaltGlow,
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.warehouse_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'ConfigTool Cobalt',
          style: TextStyle(
            color: CobaltColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'by Ingram Micro',
          style: TextStyle(
            color: CobaltColors.textSecondary,
            fontSize: 13,
            letterSpacing: 0.3,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
