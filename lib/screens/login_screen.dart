import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:go_router/go_router.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../core/colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isMacOS) return const _AppleLogin();
    if (Platform.isWindows) return const _WindowsLogin();
    return const _AndroidLogin();
  }
}

// ─── Apple (iOS + macOS) ─────────────────────────────────────────────────────

class _AppleLogin extends StatefulWidget {
  const _AppleLogin();

  @override
  State<_AppleLogin> createState() => _AppleLoginState();
}

class _AppleLoginState extends State<_AppleLogin> {
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
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    // TODO: wire to auth service
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF080C14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GradientBackground(),
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
        cornerRadius: 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sign in',
          style: TextStyle(
            color: CobaltColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Use your Ingram Micro credentials',
          style: TextStyle(
            color: CobaltColors.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        CupertinoTextField(
          controller: usernameCtrl,
          placeholder: 'Username',
          placeholderStyle: const TextStyle(color: CobaltColors.textHint),
          style: const TextStyle(color: CobaltColors.textPrimary),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CobaltColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          keyboardType: TextInputType.text,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.person, color: CobaltColors.textHint, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          controller: passwordCtrl,
          placeholder: 'Password',
          placeholderStyle: const TextStyle(color: CobaltColors.textHint),
          style: const TextStyle(color: CobaltColors.textPrimary),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CobaltColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.lock, color: CobaltColors.textHint, size: 18),
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
        CupertinoButton.filled(
          onPressed: loading ? null : onSubmit,
          borderRadius: BorderRadius.circular(12),
          color: CobaltColors.cobalt,
          child: loading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CobaltColors.background,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: CobaltColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CobaltColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Logo(),
              const SizedBox(height: 32),
              const Text(
                'Sign in',
                style: TextStyle(
                  color: CobaltColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Use your Ingram Micro credentials',
                style: TextStyle(
                  color: CobaltColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Username',
                style: TextStyle(color: CobaltColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              fluent.TextBox(
                controller: _usernameCtrl,
                placeholder: 'Enter your username',
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              const Text(
                'Password',
                style: TextStyle(color: CobaltColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              fluent.PasswordBox(
                controller: _passwordCtrl,
                placeholder: 'Enter your password',
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
                    : const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Android (Custom Cobalt) ──────────────────────────────────────────────────

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
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CobaltColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GradientBackground(),
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
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: CobaltColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CobaltColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              color: CobaltColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ingram Micro credentials',
                            style: TextStyle(
                              color: CobaltColors.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          _CobaltTextField(
                            controller: _usernameCtrl,
                            hint: 'Username',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          _CobaltTextField(
                            controller: _passwordCtrl,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _CobaltButton(
                            label: 'Sign in',
                            loading: _loading,
                            onPressed: _submit,
                          ),
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autocorrect: false,
      style: const TextStyle(color: CobaltColors.textPrimary, fontSize: 15),
      cursorColor: CobaltColors.cobalt,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CobaltColors.textHint),
        prefixIcon: Icon(icon, color: CobaltColors.textHint, size: 20),
        filled: true,
        fillColor: CobaltColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CobaltColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CobaltColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CobaltColors.cobalt, width: 1.5),
        ),
      ),
    );
  }
}

class _CobaltButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _CobaltButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CobaltColors.cobalt,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CobaltColors.cobalt.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF060810),
            Color(0xFF0B1020),
            Color(0xFF0D1530),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: CobaltColors.cobalt,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: CobaltColors.cobaltGlow,
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.warehouse_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ConfigTool Cobalt',
          style: TextStyle(
            color: CobaltColors.textPrimary,
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
