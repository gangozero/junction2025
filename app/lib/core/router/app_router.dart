/// Application routing configuration
library;

/// Declarative routing using go_router
///
/// Provides type-safe navigation with deep linking support,
/// route guards for authentication, and responsive layouts.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/logger.dart';

/// Application router configuration
class AppRouter {
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;
  AppRouter._internal();

  late final GoRouter _router;

  /// Initialize router with authentication state
  ///
  /// [isAuthenticated] - Stream of authentication state changes
  void initialize({Stream<bool>? isAuthenticated}) {
    _router = GoRouter(
      initialLocation: RoutePaths.splash,
      debugLogDiagnostics: true,
      redirect: _handleRedirect,
      refreshListenable: isAuthenticated != null
          ? _AuthStateListener(isAuthenticated)
          : null,
      routes: [
        // Splash screen
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Splash', message: 'Loading...'),
        ),

        // Authentication
        GoRoute(
          path: RoutePaths.login,
          name: RouteNames.login,
          builder: (context, state) => const _PlaceholderScreen(
            title: 'Login',
            message: 'Login screen (T030)',
          ),
        ),

        // Main app shell with navigation
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          builder: (context, state) => const _PlaceholderScreen(
            title: 'Home',
            message: 'Dashboard screen (T045)',
          ),
          routes: [
            // Dashboard
            GoRoute(
              path: RouteNames.dashboard,
              name: RouteNames.dashboard,
              builder: (context, state) => const _PlaceholderScreen(
                title: 'Dashboard',
                message: 'Dashboard screen (T045)',
              ),
            ),

            // Device detail
            GoRoute(
              path: '${RouteNames.device}/:deviceId',
              name: RouteNames.device,
              builder: (context, state) {
                final deviceId = state.pathParameters['deviceId']!;
                return _PlaceholderScreen(
                  title: 'Device',
                  message: 'Device detail: $deviceId (T045)',
                );
              },
            ),

            // Schedules
            GoRoute(
              path: RouteNames.schedules,
              name: RouteNames.schedules,
              builder: (context, state) => const _PlaceholderScreen(
                title: 'Schedules',
                message: 'Schedule list (T098)',
              ),
              routes: [
                // Schedule create/edit
                GoRoute(
                  path: '${RouteNames.scheduleForm}/:scheduleId?',
                  name: RouteNames.scheduleForm,
                  builder: (context, state) {
                    final scheduleId = state.pathParameters['scheduleId'];
                    return _PlaceholderScreen(
                      title: scheduleId == null
                          ? 'New Schedule'
                          : 'Edit Schedule',
                      message: 'Schedule form (T099)',
                    );
                  },
                ),
              ],
            ),

            // Events
            GoRoute(
              path: RouteNames.events,
              name: RouteNames.events,
              builder: (context, state) => const _PlaceholderScreen(
                title: 'Events',
                message: 'Event history (T083)',
              ),
            ),

            // Settings
            GoRoute(
              path: RouteNames.settings,
              name: RouteNames.settings,
              builder: (context, state) => const _PlaceholderScreen(
                title: 'Settings',
                message: 'Settings screen (T109)',
              ),
              routes: [
                // Notification settings
                GoRoute(
                  path: RouteNames.notificationSettings,
                  name: RouteNames.notificationSettings,
                  builder: (context, state) => const _PlaceholderScreen(
                    title: 'Notifications',
                    message: 'Notification settings (T086)',
                  ),
                ),
              ],
            ),
          ],
        ),

        // 404 Not Found
        GoRoute(
          path: RoutePaths.notFound,
          name: RouteNames.notFound,
          builder: (context, state) =>
              const _PlaceholderScreen(title: '404', message: 'Page not found'),
        ),
      ],
      errorBuilder: (context, state) => _PlaceholderScreen(
        title: 'Error',
        message: 'Route error: ${state.error}',
      ),
    );

    AppLogger.i('Router initialized');
  }

  /// Handle route redirects for authentication
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    // TODO: Get from auth provider in T029
    const isAuthenticated = false;
    final isSplash = state.matchedLocation == RoutePaths.splash;
    final isLogin = state.matchedLocation == RoutePaths.login;

    AppLogger.navigation('Router', state.matchedLocation);

    // Skip redirect logic on splash/login
    if (isSplash || isLogin) return null;

    // Redirect to login if not authenticated
    if (!isAuthenticated) {
      AppLogger.navigation(state.matchedLocation, RoutePaths.login);
      return RoutePaths.login;
    }

    // When authenticated, allow navigation
    // ignore: dead_code (temporary until T029 implements auth state)
    return null;
  }

  /// Get router instance
  GoRouter get router => _router;

  /// Navigate to route by name
  void goNamed(String name, {Map<String, String>? params}) {
    _router.goNamed(name, pathParameters: params ?? {});
  }

  /// Push route by name
  void pushNamed(String name, {Map<String, String>? params}) {
    _router.pushNamed(name, pathParameters: params ?? {});
  }

  /// Go back
  void pop() {
    _router.pop();
  }

  /// Can pop
  bool canPop() {
    return _router.canPop();
  }
}

/// Route paths
class RoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const notFound = '/404';
}

/// Route names
class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const home = 'home';
  static const dashboard = 'dashboard';
  static const device = 'device';
  static const schedules = 'schedules';
  static const scheduleForm = 'schedule-form';
  static const events = 'events';
  static const settings = 'settings';
  static const notificationSettings = 'notification-settings';
  static const notFound = 'not-found';
}

/// Authentication state listener for router refresh
class _AuthStateListener extends ChangeNotifier {
  _AuthStateListener(Stream<bool> authStream) {
    _subscription = authStream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Route: ${GoRouterState.of(context).matchedLocation}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
