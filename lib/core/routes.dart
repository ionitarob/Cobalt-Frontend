import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_placeholder.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, st) => const SplashScreen()),
    GoRoute(path: '/login', builder: (ctx, st) => const LoginScreen()),
    GoRoute(path: '/home', builder: (ctx, st) => const HomePlaceholder()),
  ],
);
