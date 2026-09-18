import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/cobalt_theme.dart';
import '../core/colors.dart';
import '../core/nav_items.dart';
import '../core/auth_service.dart';
import '../core/theme_notifier.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Material(
      color: ct.background,
      child: Row(
        children: [
          _Sidebar(
            location: location,
            user: AuthService.instance.currentUser,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(location: location),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.012),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(location),
                      child: child,
                    ),
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

// ─── Content top bar ──────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String location;
  const _TopBar({required this.location});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    NavItem? item;
    for (final i in kNavItems) {
      if (location.startsWith(i.route)) {
        item = i;
        break;
      }
    }
    if (item == null) return const SizedBox.shrink();

    final sectionLabel =
        item.section == NavSection.proyectos ? 'Proyectos' : 'Herramientas';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Container(
        key: ValueKey(item.route),
        height: 44,
        decoration: BoxDecoration(
          color: ct.background,
          border: Border(
            bottom: BorderSide(
              color: ct.border.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(
              sectionLabel,
              style: TextStyle(
                color: ct.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '/',
                style: TextStyle(
                  color: ct.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Icon(item.icon, size: 13, color: ct.textSecondary),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                color: ct.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) => IconButton(
                icon: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 16,
                  color: CobaltColors.textHint,
                ),
                onPressed: () {
                  final next = themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  themeNotifier.value = next;
                  saveTheme(next);
                },
                tooltip:
                    mode == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final String location;
  final AuthUser? user;

  const _Sidebar({required this.location, required this.user});

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(
          right: BorderSide(color: ct.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const _AppLogo(),
          Expanded(child: _NavList(location: location)),
          if (user != null) _UserCard(user: user!),
        ],
      ),
    );
  }
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ct.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: CobaltColors.cobalt.withValues(alpha: 0.10),
              border: Border.all(
                color: CobaltColors.cobalt.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CobaltColors.cobalt.withValues(alpha: 0.40),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: CobaltColors.cobalt.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/brand/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COBALT',
                style: TextStyle(
                  color: ct.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: CobaltColors.cobalt.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: CobaltColors.cobalt.withValues(alpha: 0.28),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'v3.0',
                  style: TextStyle(
                    color: CobaltColors.cobaltLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Nav list ─────────────────────────────────────────────────────────────────

class _NavList extends StatelessWidget {
  final String location;
  const _NavList({required this.location});

  @override
  Widget build(BuildContext context) {
    final proyectos =
        kNavItems.where((i) => i.section == NavSection.proyectos).toList();
    final herramientas =
        kNavItems.where((i) => i.section == NavSection.herramientas).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader('PROYECTOS'),
          ...proyectos.map((item) => _NavTile(
                item: item,
                active: location.startsWith(item.route),
              )),
          const SizedBox(height: 6),
          _SectionHeader('HERRAMIENTAS'),
          ...herramientas.map((item) => _NavTile(
                item: item,
                active: location.startsWith(item.route),
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 12, 3),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: ct.textHint,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: ct.border,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav tile ─────────────────────────────────────────────────────────────────

class _NavTile extends StatefulWidget {
  final NavItem item;
  final bool active;

  const _NavTile({required this.item, required this.active});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final bgOpacity = widget.active
        ? 0.10
        : _hovered
            ? 0.05
            : 0.0;

    final iconColor = widget.active
        ? CobaltColors.cobaltLight
        : _hovered
            ? const Color(0xFFAAB5C3)
            : ct.textSecondary;

    final labelColor = widget.active
        ? CobaltColors.cobaltLight
        : _hovered
            ? const Color(0xFFB5C0CE)
            : ct.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          context.go(widget.item.route);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            height: 34,
            child: Stack(
              children: [
                // Background highlight
                Positioned(
                  left: 8,
                  right: 8,
                  top: 2,
                  bottom: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: CobaltColors.cobalt.withValues(alpha: bgOpacity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // Left accent bar
                Positioned(
                  left: 0,
                  top: 5,
                  bottom: 5,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 2.5,
                    decoration: BoxDecoration(
                      color: widget.active
                          ? CobaltColors.cobaltLight
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: widget.active
                          ? [
                              BoxShadow(
                                color:
                                    CobaltColors.cobalt.withValues(alpha: 0.65),
                                blurRadius: 7,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                // Content row
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(widget.item.icon, size: 16, color: iconColor),
                        const SizedBox(width: 9),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 13,
                              fontWeight: widget.active
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              height: 1.2,
                            ),
                            child: Text(
                              widget.item.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  final AuthUser user;
  const _UserCard({required this.user});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _logoutHovered = false;

  String get _initials {
    final n = widget.user.nombre.isNotEmpty
        ? widget.user.nombre[0].toUpperCase()
        : '';
    final a = widget.user.apellido.isNotEmpty
        ? widget.user.apellido[0].toUpperCase()
        : '';
    return '$n$a';
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        border: Border(
          top: BorderSide(
            color: ct.border.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0052CC), CobaltColors.cobaltLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: CobaltColors.cobalt.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user.displayName,
                  style: TextStyle(
                    color: ct.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.user.role != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.user.role!,
                    style: TextStyle(
                      color: ct.textHint,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Logout button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _logoutHovered = true),
            onExit: (_) => setState(() => _logoutHovered = false),
            child: GestureDetector(
              onTap: () async {
                await AuthService.instance.clearSession();
                if (context.mounted) context.go('/login');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _logoutHovered
                      ? Colors.red.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 14,
                  color: _logoutHovered
                      ? const Color(0xFFFF6B6B)
                      : ct.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
