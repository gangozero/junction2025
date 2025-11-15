/// Application-wide string constants
library;

/// String constants used throughout the app
class AppStrings {
  AppStrings._();

  // App identity
  static const String appName = 'Harvia Sauna';
  static const String appNameShort = 'Harvia';

  // Authentication
  static const String login = 'Log In';
  static const String logout = 'Log Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String signIn = 'Sign In';
  static const String forgotPassword = 'Forgot Password?';

  // Validation messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 8 characters';

  // Error messages
  static const String networkError = 'Network connection failed';
  static const String authError = 'Authentication failed';
  static const String sessionExpired = 'Session expired. Please log in again.';
  static const String unknownError = 'An unknown error occurred';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String status = 'Status';
  static const String temperature = 'Temperature';
  static const String humidity = 'Humidity';
  static const String power = 'Power';
  static const String heating = 'Heating';

  // Common actions
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';

  // Units
  static const String celsius = '°C';
  static const String fahrenheit = '°F';
  static const String percentSymbol = '%';
}
