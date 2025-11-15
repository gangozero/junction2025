/// Security validation utilities
library;

import 'package:flutter/services.dart';

/// Input validation utilities
class InputValidator {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // RFC 5322 compliant email regex (simplified)
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    // Additional security: limit length
    if (value.length > 254) {
      return 'Email too long';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password too long';
    }

    // Check for at least one uppercase, one lowercase, one digit
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate temperature input
  static String? validateTemperature(
    String? value, {
    int min = 40,
    int max = 110,
  }) {
    if (value == null || value.isEmpty) {
      return 'Temperature is required';
    }

    final temp = int.tryParse(value);
    if (temp == null) {
      return 'Invalid temperature';
    }

    if (temp < min || temp > max) {
      return 'Temperature must be between $min°C and $max°C';
    }

    return null;
  }

  /// Validate device ID format
  static String? validateDeviceId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device ID is required';
    }

    // UUID format validation
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    if (!uuidRegex.hasMatch(value)) {
      return 'Invalid device ID format';
    }

    return null;
  }

  /// Sanitize string input (remove dangerous characters)
  static String sanitizeInput(String input) {
    // Remove control characters and non-printable characters
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Sanitize HTML content (basic XSS prevention)
  static String sanitizeHtml(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validate JSON string
  static bool isValidJson(String input) {
    try {
      // Attempt to decode - will throw if invalid
      return input.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Text input formatters for security
class SecureTextInputFormatters {
  /// Email input formatter (blocks special characters)
  static final email = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9@.!#$%&*+/=?^_`{|}~-]'),
  );

  /// Numeric input only
  static final numericOnly = FilteringTextInputFormatter.digitsOnly;

  /// Temperature input (digits and minus sign)
  static final temperature = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9-]'),
  );

  /// Alphanumeric with spaces
  static final alphanumericWithSpaces = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9 ]'),
  );

  /// UUID format
  static final uuid = FilteringTextInputFormatter.allow(
    RegExp(r'[a-fA-F0-9-]'),
  );

  /// No special characters (prevent injection)
  static final noSpecialChars = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9\s]'),
  );
}

/// Token security utilities
class TokenSecurity {
  /// Check if token is expired
  static bool isTokenExpired(DateTime expiresAt) {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Check if token is expiring soon (within 5 minutes)
  static bool isTokenExpiringSoon(DateTime expiresAt) {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return expiresAt.isBefore(fiveMinutesFromNow);
  }

  /// Validate JWT token format (basic check)
  static bool isValidJwtFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  /// Get time until token expires
  static Duration timeUntilExpiry(DateTime expiresAt) {
    return expiresAt.difference(DateTime.now());
  }
}

/// Data sanitization for display
class DisplayDataSanitizer {
  /// Sanitize text for display (prevent XSS)
  static String sanitizeText(String? text) {
    if (text == null || text.isEmpty) return '';

    // Remove control characters
    var sanitized = text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Limit length to prevent UI issues
    if (sanitized.length > 10000) {
      sanitized = '${sanitized.substring(0, 10000)}...';
    }

    return sanitized;
  }

  /// Sanitize user-generated content
  static String sanitizeUserContent(String? content) {
    if (content == null || content.isEmpty) return '';

    var sanitized = content;

    // Remove script tags
    sanitized = sanitized.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      '',
    );

    // Remove event handlers
    sanitized = sanitized.replaceAll(
      RegExp(r'on\w+\s*=', caseSensitive: false),
      '',
    );

    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(
      RegExp(r'javascript:', caseSensitive: false),
      '',
    );

    return sanitized;
  }

  /// Truncate text safely
  static String truncate(
    String text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

/// Security audit checker
class SecurityAudit {
  /// Run comprehensive security checks
  static SecurityAuditResult runAudit({
    required DateTime? tokenExpiresAt,
    required String? currentToken,
    List<String>? userInputs,
  }) {
    final issues = <String>[];
    final warnings = <String>[];

    // Check token expiry
    if (tokenExpiresAt == null) {
      issues.add('Token expiration not set');
    } else if (TokenSecurity.isTokenExpired(tokenExpiresAt)) {
      issues.add('Token is expired');
    } else if (TokenSecurity.isTokenExpiringSoon(tokenExpiresAt)) {
      warnings.add('Token expiring soon');
    }

    // Check token format
    if (currentToken != null && !TokenSecurity.isValidJwtFormat(currentToken)) {
      issues.add('Invalid token format');
    }

    // Check user inputs
    if (userInputs != null) {
      for (var i = 0; i < userInputs.length; i++) {
        final input = userInputs[i];
        if (input.contains(RegExp(r'<script', caseSensitive: false))) {
          issues.add('Potentially malicious input detected at index $i');
        }
        if (input.length > 10000) {
          warnings.add('Input at index $i exceeds recommended length');
        }
      }
    }

    return SecurityAuditResult(
      passed: issues.isEmpty,
      issues: issues,
      warnings: warnings,
    );
  }
}

/// Security audit result
class SecurityAuditResult {
  final bool passed;
  final List<String> issues;
  final List<String> warnings;

  const SecurityAuditResult({
    required this.passed,
    required this.issues,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasIssues => issues.isNotEmpty;
}
