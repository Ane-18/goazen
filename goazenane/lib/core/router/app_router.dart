import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/workout/screens/workout_screen.dart';
import '../../features/session/screens/active_session_screen.dart';
import '../../features/session/screens/warmup_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/mi_band_setup_screen.dart';
import '../../features/progress/screens/photo_diary_screen.dart';
import '../../features/progress/screens/body_metrics_screen.dart';
import '../../features/workout/screens/how_routine_works_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Escucha userProvider y notifica a GoRouter para re-evaluar el redirect
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(userProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final userAsync = _ref.read(userProvider);

    if (userAsync.isLoading) return null;
    if (userAsync.hasError) return null;

    final isOnboarded = userAsync.value?.onboardingCompleto == true;
    final goingToOnboarding = state.matchedLocation.startsWith('/onboarding');

    if (!isOnboarded && !goingToOnboarding) return '/onboarding';
    if (isOnboarded && goingToOnboarding) return '/home';

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/workout',
            builder: (context, state) => const WorkoutScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/session/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['sessionId']!);
          return ActiveSessionScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/warmup/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['sessionId']!);
          return WarmupScreen(sessionId: id);
        },
      ),
      GoRoute(
        path: '/photos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PhotoDiaryScreen(),
      ),
      GoRoute(
        path: '/body-metrics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BodyMetricsScreen(),
      ),
      GoRoute(
        path: '/mi-band-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MiBandSetupScreen(),
      ),
      GoRoute(
        path: '/how-routine-works',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HowRoutineWorksScreen(),
      ),
    ],
  );
});

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _indexToRoute(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Entrenar'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  int _locationToIndex(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/workout')) return 1;
    if (loc.startsWith('/progress')) return 2;
    return 3;
  }

  void _indexToRoute(BuildContext context, int i) {
    const routes = ['/home', '/workout', '/progress', '/profile'];
    context.go(routes[i]);
  }
}
