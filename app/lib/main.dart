import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'services/storage/hive_service.dart';

/// Entry point for Harvia MSGA application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await HiveService.initialize();

  runApp(const ProviderScope(child: HarviaMsgaApp()));
}

/// Root application widget
class HarviaMsgaApp extends StatelessWidget {
  const HarviaMsgaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harvia MSGA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Authentication gate widget
///
/// Routes user to login or dashboard based on auth state
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading indicator while checking auth state
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Route based on authentication status
    return authState.isAuthenticated
        ? const DashboardScreen()
        : const LoginScreen();
  }
}
