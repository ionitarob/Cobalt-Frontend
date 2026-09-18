import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../core/cobalt_theme.dart';
import '../core/colors.dart';
import '../core/auth_service.dart';
import '../core/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Two panels slide in from opposite edges
  late final Animation<double> _panelSlide;
  // Elastic punch at snap moment
  late final Animation<double> _snapScale;
  // White flash at impact
  late final Animation<double> _snapFlash;
  // Cobalt glow bloom
  late final Animation<double> _snapGlow;
  // Panels dissolve after snap
  late final Animation<double> _panelFade;
  // Logo springs in
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  // "ConfigTool Cobalt" slides up
  late final Animation<double> _titleOpacity;
  // "INGRAM MICRO" fades in last
  late final Animation<double> _subtitleOpacity;
  // No exit fade — page transition handles it

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Panels slide in — 0% → 28% (0–784ms), crisp ease-out
    _panelSlide = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 72),
    ]).animate(_ctrl);

    // Elastic punch — 26% → 43%
    _snapScale = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 26),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.045)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.045, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 54),
    ]).animate(_ctrl);

    // White flash — 26% → 38%
    _snapFlash = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 26),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.8),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 9,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 62),
    ]).animate(_ctrl);

    // Cobalt glow — 26% → 52%
    _snapGlow = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 26),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 7,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 19,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
    ]).animate(_ctrl);

    // Panel dissolve — 30% → 48%
    _panelFade = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 52),
    ]).animate(_ctrl);

    // Logo opacity — 35% → 50%
    _logoOpacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_ctrl);

    // Logo scale — spring from near-full (never from near-zero)
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.72), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 47),
    ]).animate(_ctrl);

    // Title — 43% → 56%
    _titleOpacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 43),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 13,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 44),
    ]).animate(_ctrl);

    // Subtitle — 51% → 62%
    _subtitleOpacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 51),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 11,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 38),
    ]).animate(_ctrl);

    _ctrl.forward();
    // Attempt silent refresh in parallel with the animation.
    // Both paths converge at 1900ms so the user always sees the full intro.
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    // Run both in parallel: wait for the minimum display time AND the refresh attempt
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1900)),
      _trySilentRefresh(),
    ]);
    if (!mounted) return;
    final isAuthenticated = results[1] as bool;
    context.go(isAuthenticated ? '/home' : '/login');
  }

  Future<bool> _trySilentRefresh() async {
    final refreshToken = await AuthService.instance.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final resp = await ApiClient.instance.dio.post(
        '/api/auth/refresh/',
        data: {'refresh_token': refreshToken},
      );
      final body = resp.data as Map<String, dynamic>;
      await AuthService.instance.persistSession(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
      return true;
    } on DioException {
      await AuthService.instance.clearSession();
      return false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final hw = w / 2;

          return AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, _) {
              // Left slides from -hw → 0; right slides from +hw → 0
              final leftX = -hw * (1.0 - _panelSlide.value);
              final rightX = hw * (1.0 - _panelSlide.value);

              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF040608)),

                  // ── Starfield depth layer ─────────────────────────────────
                  Positioned.fill(
                    child: CustomPaint(painter: _StarfieldPainter()),
                  ),

                  // ── Content (logo + text) revealed behind panels ──────────
                  if (_logoOpacity.value > 0)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Hero(
                                tag: 'cobalt-logo',
                                child: Image.asset(
                                  'assets/brand/logo.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                            const SizedBox(height: 32),
                            Opacity(
                              opacity: _titleOpacity.value,
                              child: Transform.translate(
                                offset: Offset(
                                    0, (1.0 - _titleOpacity.value) * 18),
                                child: Text(
                                  'ConfigTool Cobalt',
                                  style: TextStyle(
                                    color: ct.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Opacity(
                              opacity: _subtitleOpacity.value,
                              child: Transform.translate(
                                offset: Offset(
                                    0, (1.0 - _subtitleOpacity.value) * 10),
                                child: Text(
                                  'INGRAM MICRO',
                                  style: TextStyle(
                                    color: ct.textHint,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 4,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                  // ── Two panels (both scaled together at snap) ─────────────
                  if (_panelFade.value > 0)
                    Opacity(
                      opacity: _panelFade.value,
                      child: Transform.scale(
                        scale: _snapScale.value,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Left panel
                            Positioned(
                              left: 0, top: 0, width: hw, height: h,
                              child: ClipRect(
                                child: Transform.translate(
                                  offset: Offset(leftX, 0),
                                  child: SizedBox(
                                    width: hw,
                                    height: h,
                                    child: const _Panel(side: _PanelSide.left),
                                  ),
                                ),
                              ),
                            ),
                            // Right panel
                            Positioned(
                              left: hw, top: 0, width: hw, height: h,
                              child: ClipRect(
                                child: Transform.translate(
                                  offset: Offset(rightX, 0),
                                  child: SizedBox(
                                    width: hw,
                                    height: h,
                                    child: const _Panel(side: _PanelSide.right),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Cobalt glow bloom at snap ─────────────────────────────
                  if (_snapGlow.value > 0)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GlowPainter(progress: _snapGlow.value),
                      ),
                    ),

                  // ── White snap flash ──────────────────────────────────────
                  if (_snapFlash.value > 0)
                    Opacity(
                      opacity: _snapFlash.value,
                      child: const ColoredBox(color: Colors.white),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Panel widget ─────────────────────────────────────────────────────────────

enum _PanelSide { left, right }

class _Panel extends StatelessWidget {
  final _PanelSide side;
  const _Panel({required this.side});

  @override
  Widget build(BuildContext context) {
    final isLeft = side == _PanelSide.left;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep cobalt gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.topLeft : Alignment.topRight,
              end: isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
              colors: const [
                Color(0xFF0E1E3A),
                Color(0xFF071428),
                Color(0xFF040A18),
              ],
            ),
          ),
        ),
        // Subtle grid overlay
        CustomPaint(painter: _GridPainter()),
        // Edge highlight (faint outer glow on non-joining side)
        Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  CobaltColors.cobalt.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Inner joining rail — glows at the snap edge
        Align(
          alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  CobaltColors.cobalt.withValues(alpha: 0.5),
                  CobaltColors.cobaltLight.withValues(alpha: 0.95),
                  CobaltColors.cobalt.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
        ),
        // Small center marker on the rail (the "click point")
        Center(
          child: Align(
            alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: CobaltColors.cobaltLight,
                boxShadow: [
                  BoxShadow(
                    color: CobaltColors.cobalt.withValues(alpha: 0.9),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Grid painter — radar rings + radial spokes ────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    // Concentric rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const rings = 7;
    for (int i = 1; i <= rings; i++) {
      final r = (i / rings) * maxR * 0.95;
      final alpha = 0.11 * (1.0 - (i - 1) / rings);
      ringPaint.color = CobaltColors.cobalt.withValues(alpha: alpha);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Radial spokes
    final spokePaint = Paint()
      ..strokeWidth = 0.4
      ..color = CobaltColors.cobalt.withValues(alpha: 0.045);
    const spokes = 16;
    for (int i = 0; i < spokes; i++) {
      final angle = (i / spokes) * math.pi * 2;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * maxR, center.dy + math.sin(angle) * maxR),
        spokePaint,
      );
    }

    // Crosshair marks on the middle ring
    final crossPaint = Paint()
      ..strokeWidth = 0.8
      ..color = CobaltColors.cobalt.withValues(alpha: 0.18);
    final midR = maxR * 0.5;
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2;
      final cx = center.dx + math.cos(angle) * midR;
      final cy = center.dy + math.sin(angle) * midR;
      canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), crossPaint);
      canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), crossPaint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─── Starfield painter ────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(17);
    final paint = Paint();
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.35 + rng.nextDouble() * 0.75;
      paint.color = Colors.white.withValues(alpha: 0.05 + rng.nextDouble() * 0.13);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}

// ─── Glow painter ─────────────────────────────────────────────────────────────

class _GlowPainter extends CustomPainter {
  final double progress;
  const _GlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR =
        math.sqrt(size.width * size.width + size.height * size.height) / 2 * 0.75;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          CobaltColors.cobalt.withValues(alpha: 0.55 * progress),
          CobaltColors.cobalt.withValues(alpha: 0.18 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));

    canvas.drawCircle(center, maxR, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => progress != old.progress;
}
