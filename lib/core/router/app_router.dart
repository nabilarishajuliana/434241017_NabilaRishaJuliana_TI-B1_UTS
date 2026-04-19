import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../presentation/screens/main_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/ticket/create_ticket_screen.dart';
import '../../presentation/screens/ticket/detail_ticket_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/reset-password';

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (c, s) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (c, s) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (c, s) => const ResetPasswordScreen(),
      ),
      // Main screen dengan bottom navbar
      GoRoute(
        path: '/dashboard',
        builder: (c, s) => const MainScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/tickets',
        builder: (c, s) => const MainScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/history',
        builder: (c, s) => const MainScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/profile',
        builder: (c, s) => const MainScreen(initialIndex: 3),
      ),
      // Screen yang tidak pakai navbar
      GoRoute(
        path: '/tickets/create',
        builder: (c, s) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (c, s) => DetailTicketScreen(
          ticketId: s.pathParameters['id']!,
        ),
      ),
    ],
  );
}