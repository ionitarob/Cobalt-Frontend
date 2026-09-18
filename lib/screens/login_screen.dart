import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:go_router/go_router.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:dio/dio.dart';

import '../core/cobalt_theme.dart';
import '../core/colors.dart';
import '../core/flavor.dart';
import '../core/auth_service.dart';
import '../core/api_client.dart';
import '../services/health_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) return const _MacOSLogin();
    if (Platform.isIOS) return const _IOSLogin();
    if (Platform.isWindows) return const _WindowsLogin();
    return const _AndroidLogin();
  }
}

// ─── macOS — split panel ──────────────────────────────────────────────────────

class _MacOSLogin extends StatefulWidget {
  const _MacOSLogin();

  @override
  State<_MacOSLogin> createState() => _MacOSLoginState();
}

class _MacOSLoginState extends State<_MacOSLogin> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    HealthService.instance.startPolling();
  }

  @override
  void dispose() {
    HealthService.instance.stopPolling();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu usuario y contraseña.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.instance.dio.post(
        '/api/auth/login/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      await AuthService.instance.persistSession(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String?
          ?? 'Error de conexión. Inténtalo de nuevo.';
      if (!mounted) return;
      setState(() { _error = msg; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Error inesperado.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Material(
      color: ct.background,
      child: Row(
        children: [
          // ── Left branding panel ────────────────────────────────────────────
          Expanded(child: _LeftPanel()),
          // Gradient divider
          Container(
            width: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xFF0047AB),
                  Color(0xFF1A6FDB),
                  Color(0xFF0047AB),
                  Colors.transparent,
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          // ── Right form panel ───────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF070E1C), Color(0xFF040810)],
                  stops: [0.0, 0.55],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle top aurora echo
                  Positioned(
                    top: -80,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.7,
                          colors: [
                            CobaltColors.cobalt.withValues(alpha: 0.055),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                children: [
                  // Health status badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
                    child: ListenableBuilder(
                      listenable: HealthService.instance,
                      builder: (context, _) {
                        final s = HealthService.instance.status;
                        return _HealthBadge(status: s);
                      },
                    ),
                  ),
                  // Form
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  color: ct.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Credenciales del nodo de almacén.',
                                style: TextStyle(
                                  color: ct.textSecondary,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 36),
                              _DesktopField(
                                controller: _usernameCtrl,
                                label: 'USUARIO',
                                hint: 'nombre.apellido',
                                icon: CupertinoIcons.person,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                              _DesktopField(
                                controller: _passwordCtrl,
                                label: 'CONTRASEÑA',
                                hint: '••••••••',
                                icon: CupertinoIcons.lock,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                child: _error != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 220),
                                          switchInCurve: Curves.easeOut,
                                          transitionBuilder: (child, anim) => FadeTransition(
                                            opacity: anim,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, -0.35),
                                                end: Offset.zero,
                                              ).animate(anim),
                                              child: child,
                                            ),
                                          ),
                                          child: Container(
                                            key: ValueKey(_error),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  CupertinoIcons.exclamationmark_circle,
                                                  color: Color(0xFFFF453A),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _error!,
                                                  style: const TextStyle(
                                                    color: Color(0xFFFF453A),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 28),
                              _GlowButton(
                                loading: _loading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {},
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: CobaltColors.cobaltLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // TLS footer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: ct.textHint,
                          size: 11,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Conexión protegida con TLS 1.3',
                          style: TextStyle(color: ct.textHint, fontSize: 11),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Left branding panel ──────────────────────────────────────────────────────

class _LeftPanel extends StatefulWidget {
  @override
  State<_LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<_LeftPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_breathe.value);
        final primaryAlpha = 0.15 + 0.08 * t;
        final primaryMidAlpha = 0.05 + 0.03 * t;
        final secondaryAlpha = 0.07 + 0.06 * t;
        return Container(
          color: const Color(0xFF040A18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Aurora glow — breathes slowly
              Positioned(
                left: -80,
                top: -80,
                right: -80,
                child: Container(
                  height: 600,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.75,
                      colors: [
                        CobaltColors.cobalt.withValues(alpha: primaryAlpha),
                        CobaltColors.cobalt.withValues(alpha: primaryMidAlpha),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Secondary smaller glow lower-right
              Positioned(
                right: -40,
                bottom: 80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        CobaltColors.cobalt.withValues(alpha: secondaryAlpha),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle grid overlay
          CustomPaint(
            painter: _LeftPanelGridPainter(),
            size: Size.infinite,
          ),
          // Bottom gradient fade
          Positioned(
            bottom: 0, left: 0, right: 0, height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    CobaltColors.cobalt.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                // Logo with glow ring
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: CobaltColors.cobalt.withValues(alpha: 0.12),
                    border: Border.all(
                      color: CobaltColors.cobalt.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CobaltColors.cobalt.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: CobaltColors.cobalt.withValues(alpha: 0.12),
                        blurRadius: 56,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Hero(
                      tag: 'cobalt-logo',
                      child: Image.asset(
                        'assets/brand/logo.png',
                        width: 46,
                        height: 46,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ConfigTool Cobalt',
                  style: TextStyle(
                    color: ct.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistema de Inteligencia de Almacén',
                  style: TextStyle(
                    color: CobaltColors.cobaltLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),
                // Cobalt accent line
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1A6FDB),
                        Color(0xFF0047AB),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© 2025 INGRAM MICRO',
                      style: TextStyle(
                        color: ct.textHint,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (kIsBeta)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CobaltColors.cobalt.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CobaltColors.cobalt.withValues(alpha: 0.35),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'v3.0',
                            style: TextStyle(
                              color: CobaltColors.cobaltLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftPanelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 56.0;
    final linePaint = Paint()
      ..color = CobaltColors.cobalt.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    final nodeFill = Paint()..style = PaintingStyle.fill;
    final nodeRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Circuit nodes at every 3rd intersection
    for (var y = step; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        final ix = (x / step).round();
        final iy = (y / step).round();
        if ((ix + iy) % 3 == 0) {
          nodeFill.color = CobaltColors.cobalt.withValues(alpha: 0.20);
          canvas.drawCircle(Offset(x, y), 1.5, nodeFill);
          nodeRing.color = CobaltColors.cobalt.withValues(alpha: 0.08);
          canvas.drawCircle(Offset(x, y), 3.5, nodeRing);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LeftPanelGridPainter old) => false;
}

// ─── Animated desktop field ───────────────────────────────────────────────────

class _DesktopField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _DesktopField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_DesktopField> createState() => _DesktopFieldState();
}

class _DesktopFieldState extends State<_DesktopField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            color: _focused ? CobaltColors.cobaltLight : ct.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _focused
                ? CobaltColors.cobalt.withValues(alpha: 0.06)
                : ct.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? CobaltColors.cobalt : ct.border,
              width: _focused ? 1.5 : 1.0,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: CobaltColors.cobalt.withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: CupertinoTextField(
            controller: widget.controller,
            focusNode: _focus,
            placeholder: widget.hint,
            placeholderStyle: TextStyle(
              color: ct.textHint,
              fontSize: 14,
            ),
            style: TextStyle(color: ct.textPrimary, fontSize: 14),
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            autocorrect: false,
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.fromLTRB(0, 13, 14, 13),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.icon,
                  key: ValueKey(_focused),
                  color: _focused
                      ? CobaltColors.cobaltLight
                      : ct.textHint,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Gradient glow button ─────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _GlowButton({required this.loading, required this.onPressed});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _pressed && !widget.loading;
    return AnimatedScale(
      scale: active ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: widget.loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0047AB), Color(0xFF1A6FDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: widget.loading ? CobaltColors.cobalt.withValues(alpha: 0.35) : null,
          boxShadow: widget.loading
              ? []
              : [
                  BoxShadow(
                    color: CobaltColors.cobalt.withValues(alpha: active ? 0.22 : 0.4),
                    blurRadius: active ? 8 : 20,
                    offset: Offset(0, active ? 2 : 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.loading ? null : (_) => setState(() => _pressed = true),
            onTapUp: widget.loading
                ? null
                : (_) {
                    setState(() => _pressed = false);
                    widget.onPressed();
                  },
            onTapCancel: () => setState(() => _pressed = false),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Entrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── iOS ──────────────────────────────────────────────────────────────────────

class _IOSLogin extends StatefulWidget {
  const _IOSLogin();

  @override
  State<_IOSLogin> createState() => _IOSLoginState();
}

class _IOSLoginState extends State<_IOSLogin> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu usuario y contraseña.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.instance.dio.post(
        '/api/auth/login/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      await AuthService.instance.persistSession(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String?
          ?? 'Error de conexión. Inténtalo de nuevo.';
      if (!mounted) return;
      setState(() { _error = msg; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Error inesperado.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF060A14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CobaltGradient(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Logo(),
                    const SizedBox(height: 36),
                    _AppleCard(
                      child: _AppleForm(
                        usernameCtrl: _usernameCtrl,
                        passwordCtrl: _passwordCtrl,
                        loading: _loading,
                        error: _error,
                        onSubmit: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleCard extends StatelessWidget {
  final Widget child;
  const _AppleCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      config: const LiquidGlassConfig(
        effect: LiquidGlassEffect.regular,
        shape: LiquidGlassEffectShape.rect,
        cornerRadius: 24,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            padding: const EdgeInsets.all(32),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppleForm extends StatelessWidget {
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _AppleForm({
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Iniciar sesión',
          style: TextStyle(
            color: ct.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Usa tus credenciales de Ingram Micro',
          style: TextStyle(color: ct.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        CupertinoTextField(
          controller: usernameCtrl,
          placeholder: 'Usuario',
          placeholderStyle: TextStyle(color: ct.textHint),
          style: TextStyle(color: ct.textPrimary),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          autocorrect: false,
          textInputAction: TextInputAction.next,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.person, color: ct.textHint, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          controller: passwordCtrl,
          placeholder: 'Contraseña',
          placeholderStyle: TextStyle(color: ct.textHint),
          style: TextStyle(color: ct.textPrimary),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.lock, color: ct.textHint, size: 18),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF0047AB), Color(0xFF1A6FDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: CobaltColors.cobalt.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CupertinoButton(
            onPressed: loading ? null : onSubmit,
            borderRadius: BorderRadius.circular(14),
            padding: EdgeInsets.zero,
            color: Colors.transparent,
            child: loading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Windows (Fluent UI) ──────────────────────────────────────────────────────

class _WindowsLogin extends StatefulWidget {
  const _WindowsLogin();

  @override
  State<_WindowsLogin> createState() => _WindowsLoginState();
}

class _WindowsLoginState extends State<_WindowsLogin> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu usuario y contraseña.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.instance.dio.post(
        '/api/auth/login/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      await AuthService.instance.persistSession(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String?
          ?? 'Error de conexión. Inténtalo de nuevo.';
      if (!mounted) return;
      setState(() { _error = msg; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Error inesperado.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Stack(
      fit: StackFit.expand,
      children: [
        _CobaltGradient(),
        Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: ct.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ct.border),
              boxShadow: [
                BoxShadow(
                  color: CobaltColors.cobalt.withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Logo(),
                const SizedBox(height: 32),
                Text(
                  'Iniciar sesión',
                  style: TextStyle(color: ct.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usa tus credenciales de Ingram Micro',
                  style: TextStyle(color: ct.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Text('Usuario', style: TextStyle(color: ct.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                fluent.TextBox(
                  controller: _usernameCtrl,
                  placeholder: 'Ingresa tu usuario',
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                Text('Contraseña', style: TextStyle(color: ct.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                fluent.PasswordBox(
                  controller: _passwordCtrl,
                  placeholder: 'Ingresa tu contraseña',
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  fluent.InfoBar(
                    title: Text(_error!),
                    severity: fluent.InfoBarSeverity.error,
                  ),
                ],
                const SizedBox(height: 24),
                fluent.FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const fluent.ProgressRing(strokeWidth: 2)
                      : const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Android ──────────────────────────────────────────────────────────────────

class _AndroidLogin extends StatefulWidget {
  const _AndroidLogin();

  @override
  State<_AndroidLogin> createState() => _AndroidLoginState();
}

class _AndroidLoginState extends State<_AndroidLogin> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu usuario y contraseña.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiClient.instance.dio.post(
        '/api/auth/login/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      await AuthService.instance.persistSession(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String?
          ?? 'Error de conexión. Inténtalo de nuevo.';
      if (!mounted) return;
      setState(() { _error = msg; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Error inesperado.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Scaffold(
      backgroundColor: ct.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CobaltGradient(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Logo(),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: ct.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ct.border),
                        boxShadow: [
                          BoxShadow(
                            color: CobaltColors.cobalt.withValues(alpha: 0.1),
                            blurRadius: 32,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              color: ct.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Credenciales de Ingram Micro',
                            style: TextStyle(color: ct.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          _CobaltTextField(
                            controller: _usernameCtrl,
                            hint: 'Usuario',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          _CobaltTextField(
                            controller: _passwordCtrl,
                            hint: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _CobaltButton(label: 'Iniciar sesión', loading: _loading, onPressed: _submit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Health status badge ──────────────────────────────────────────────────────

class _HealthBadge extends StatelessWidget {
  final HealthStatus status;
  const _HealthBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final (dotColor, glowColor, label) = switch (status) {
      HealthStatus.ok => (
          const Color(0xFF00C853),
          const Color(0xFF00C853),
          'SERVIDOR ACTIVO',
        ),
      HealthStatus.degraded => (
          const Color(0xFFFFB300),
          const Color(0xFFFFB300),
          'CONEXIÓN DEGRADADA',
        ),
      HealthStatus.unreachable => (
          const Color(0xFFFF3B30),
          const Color(0xFFFF3B30),
          'SIN CONEXIÓN',
        ),
      HealthStatus.checking => (
          const Color(0xFF8B93A0),
          const Color(0xFF8B93A0),
          'VERIFICANDO...',
        ),
    };

    return Row(
      children: [
        _PulseDot(
          color: dotColor,
          glowColor: glowColor,
          pulse: status == HealthStatus.ok || status == HealthStatus.checking,
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.6),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            label,
            key: ValueKey(status),
            style: TextStyle(
              color: ct.textHint,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final Color glowColor;
  final bool pulse;

  const _PulseDot({required this.color, required this.glowColor, this.pulse = false});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !old.pulse) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && old.pulse) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = widget.pulse ? Curves.easeInOut.transform(_ctrl.value) : 0.6;
        final alpha = 0.45 + 0.55 * t;
        final blurRadius = 4.0 + 4.0 * t;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: alpha),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.65 * alpha),
                blurRadius: blurRadius,
                spreadRadius: 0.5 + 0.5 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _CobaltGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [
            Color(0xFF0A1428),
            Color(0xFF060A14),
            Color(0xFF040608),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'cobalt-logo',
          child: Image.asset('assets/brand/logo.png', width: 80, height: 80, fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        Text(
          'ConfigTool Cobalt',
          style: TextStyle(
            color: ct.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

class _CobaltTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _CobaltTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autocorrect: false,
      style: TextStyle(color: ct.textPrimary, fontSize: 15),
      cursorColor: CobaltColors.cobalt,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: ct.textHint),
        prefixIcon: Icon(icon, color: ct.textHint, size: 20),
        filled: true,
        fillColor: ct.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ct.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ct.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CobaltColors.cobalt, width: 1.5),
        ),
      ),
    );
  }
}

class _CobaltButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _CobaltButton({required this.label, required this.loading, required this.onPressed});

  @override
  State<_CobaltButton> createState() => _CobaltButtonState();
}

class _CobaltButtonState extends State<_CobaltButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _pressed && !widget.loading;
    return AnimatedScale(
      scale: active ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: widget.loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0047AB), Color(0xFF1A6FDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: widget.loading ? CobaltColors.cobalt.withValues(alpha: 0.35) : null,
          boxShadow: widget.loading
              ? []
              : [
                  BoxShadow(
                    color: CobaltColors.cobalt.withValues(alpha: active ? 0.22 : 0.4),
                    blurRadius: active ? 8 : 20,
                    offset: Offset(0, active ? 2 : 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.loading ? null : (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: InkWell(
              onTap: widget.loading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
