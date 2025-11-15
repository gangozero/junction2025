/// Auth state and providers
library;

/// Authentication state management
///
/// Provides Riverpod providers for authentication state,
/// including login, logout, and session management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/api_session.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Auth state provider
///
/// Manages authentication state and provides methods for login/logout.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Authentication state
class AuthState {
  final APISession? session;
  final UserAccount? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.session,
    this.user,
    this.isLoading = false,
    this.error,
  });

  /// Check if user is authenticated
  bool get isAuthenticated =>
      session != null && user != null && session!.isValid;

  /// Copy with updated fields
  AuthState copyWith({
    APISession? session,
    UserAccount? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      user: clearSession ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Create initial unauthenticated state
  factory AuthState.initial() {
    return const AuthState();
  }

  /// Create loading state
  AuthState toLoading() {
    return copyWith(isLoading: true, clearError: true);
  }

  /// Create authenticated state
  AuthState toAuthenticated(APISession session, UserAccount user) {
    return AuthState(
      session: session,
      user: user,
      isLoading: false,
      error: null,
    );
  }

  /// Create unauthenticated state
  AuthState toUnauthenticated({String? error}) {
    return AuthState(session: null, user: null, isLoading: false, error: error);
  }

  /// Create error state
  AuthState toError(String error) {
    return copyWith(isLoading: false, error: error);
  }
}

/// Auth state notifier
///
/// Manages authentication state changes and coordinates with repository.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _loadSession();
  }

  /// Load saved session on initialization
  Future<void> _loadSession() async {
    final sessionResult = await _repository.getCurrentSession();
    final userResult = await _repository.getCurrentUser();

    sessionResult.fold(
      (failure) => null, // Ignore failure - user not logged in
      (session) {
        if (session != null && session.isValid) {
          userResult.fold((failure) => null, (user) {
            if (user != null) {
              state = state.toAuthenticated(session, user);
            }
          });
        }
      },
    );
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
  }) async {
    state = state.toLoading();

    final result = await _repository.login(
      email: email,
      password: password,
      deviceId: deviceId,
      deviceName: deviceName,
    );

    result.fold(
      (failure) {
        state = state.toError(failure.userMessage);
      },
      (data) {
        final (session, user) = data;
        state = state.toAuthenticated(session, user);
      },
    );
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.toLoading();

    final result = await _repository.logout();

    result.fold(
      (failure) {
        // Even if logout fails, clear local state
        state = state.toUnauthenticated(error: failure.userMessage);
      },
      (_) {
        state = state.toUnauthenticated();
      },
    );
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    final currentSession = state.session;
    if (currentSession == null || currentSession.refreshToken.isEmpty) {
      return false;
    }

    final result = await _repository.refreshToken(
      refreshToken: currentSession.refreshToken,
    );

    return result.fold(
      (failure) {
        // Token refresh failed - logout user
        state = state.toUnauthenticated(error: 'Session expired');
        return false;
      },
      (newSession) {
        // Update session with new tokens
        state = state.copyWith(session: newSession);
        return true;
      },
    );
  }

  /// Check if session is expiring soon and refresh if needed
  Future<void> checkAndRefreshToken() async {
    if (state.session != null && state.session!.isExpiringSoon) {
      await refreshToken();
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
