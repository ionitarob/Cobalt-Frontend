import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/areas/area_placeholder.dart';
import '../screens/ordenes_cf/orders_screen.dart';
import '../screens/ordenes_cf/detail/order_detail_screen.dart';
import '../core/nav_items.dart';
import '../core/auth_service.dart';
import '../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authenticated = AuthService.instance.isAuthenticated;
    final loc = state.matchedLocation;

    // Splash handles its own auth check — never redirect away from it here
    if (loc == '/') return null;

    // Redirect /home to the default area
    if (loc == '/home') return '/home/ordenes-cf';

    // Logged-in users go straight to the app
    if (loc == '/login' && authenticated) return '/home/ordenes-cf';

    // Protected routes require authentication
    if (loc.startsWith('/home') && !authenticated) return '/login';

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (ctx, st) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (ctx, st) => CustomTransitionPage(
        key: st.pageKey,
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    ),
    ShellRoute(
      builder: (ctx, state, child) => AppShell(
        location: state.uri.path,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/home/ordenes-cf/:idnbr',
          pageBuilder: (ctx, st) {
            final raw = st.pathParameters['idnbr'] ?? '0';
            final idnbr = int.tryParse(raw) ?? 0;
            return NoTransitionPage(child: OrderDetailScreen(idnbr: idnbr));
          },
        ),
        GoRoute(
          path: '/home/ordenes-cf',
          pageBuilder: (ctx, st) => const NoTransitionPage(
            child: OrdersScreen(),
          ),
        ),
        GoRoute(
          path: '/home/amazon',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[1]),
          ),
        ),
        GoRoute(
          path: '/home/analisis',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[2]),
          ),
        ),
        GoRoute(
          path: '/home/xiaomi',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[3]),
          ),
        ),
        GoRoute(
          path: '/home/revision-tv',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[4]),
          ),
        ),
        GoRoute(
          path: '/home/servidores',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[5]),
          ),
        ),
        GoRoute(
          path: '/home/sentinel',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[6]),
          ),
        ),
        GoRoute(
          path: '/home/bartender',
          pageBuilder: (ctx, st) => NoTransitionPage(
            child: AreaPlaceholder.fromItem(kNavItems[7]),
          ),
        ),
      ],
    ),
  ],
);
