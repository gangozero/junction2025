/// Auth error message mapper
library;

import '../../../../core/error/failures.dart';

/// Maps authentication failures to user-friendly messages
class AuthErrorMapper {
  AuthErrorMapper._();

  /// Get user-friendly error message from failure
  static String getMessage(Failure failure) {
    if (failure is AuthFailure) {
      return _getAuthFailureMessage(failure);
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network and try again.';
    } else if (failure is TimeoutFailure) {
      return 'Request timed out. Please try again.';
    } else if (failure is ServerFailure) {
      return failure.userMessage.isNotEmpty
          ? failure.userMessage
          : 'Server error occurred. Please try again later.';
    } else if (failure is ApiFailure) {
      return failure.userMessage.isNotEmpty
          ? failure.userMessage
          : 'An error occurred. Please try again.';
    } else if (failure is SecureStorageFailure) {
      return 'Failed to access secure storage. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get specific auth failure messages
  static String _getAuthFailureMessage(AuthFailure failure) {
    switch (failure.reason) {
      case AuthFailureReason.invalidCredentials:
        return 'Invalid email or password. Please try again.';

      case AuthFailureReason.unauthorized:
        return 'Your session has expired. Please log in again.';

      case AuthFailureReason.tokenExpired:
        return 'Your session has expired. Please log in again.';

      case AuthFailureReason.tokenInvalid:
        return 'Invalid authentication token. Please log in again.';

      case AuthFailureReason.refreshFailed:
        return 'Failed to refresh session. Please log in again.';

      case AuthFailureReason.unknown:
      case null:
        return failure.userMessage.isNotEmpty
            ? failure.userMessage
            : 'Authentication failed. Please try again.';
    }
  }
}
