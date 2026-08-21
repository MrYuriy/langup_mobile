import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/language_gate_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/review/review_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/vocabulary/vocabulary_screen.dart';
import '../features/vocabulary/word_detail_screen.dart';
import 'providers.dart';

/// Rebuilds the router whenever the auth status changes so `redirect` re-runs.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(
      authControllerProvider.select((s) => s.status),
      (_, _) => notifyListeners(),
    );
  }
}

/// Locations reachable once signed in (shell branches + full-screen pushes).
const _authedPrefixes = [
  '/words',
  '/practice',
  '/review',
  '/dashboard',
  '/profile',
  '/vocabulary',
];

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/language', builder: (_, _) => const LanguageGateScreen()),

      // Full-screen word detail (pushed over the shell).
      GoRoute(
        path: '/vocabulary/:uuid',
        builder: (_, state) =>
            WordDetailScreen(uuid: state.pathParameters['uuid']!),
      ),

      // Authenticated tabs.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/words', builder: (_, _) => const VocabularyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/practice', builder: (_, _) => const PracticeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      switch (status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return loc == '/login' ? null : '/login';
        case AuthStatus.needsLanguage:
          return loc == '/language' ? null : '/language';
        case AuthStatus.authenticated:
          final ok = _authedPrefixes.any(loc.startsWith);
          return ok ? null : '/words';
      }
    },
  );
});
