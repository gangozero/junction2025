# Security Audit & Best Practices

## Overview

This document outlines the security measures implemented in the Harvia Sauna Controller Flutter application to protect user data, prevent common vulnerabilities, and ensure safe operation.

## 1. Input Validation

### Email Validation
- **Location**: `lib/core/utils/security.dart` → `InputValidator.validateEmail()`
- **Protection**: RFC 5322 compliant regex, length limits (max 254 chars)
- **Use Case**: Login screen, user profile

### Password Strength
- **Location**: `lib/core/utils/security.dart` → `InputValidator.validatePassword()`
- **Requirements**: 
  - Minimum 8 characters
  - Maximum 128 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one digit
- **Use Case**: Registration, password change

### Temperature Input
- **Location**: `lib/core/utils/security.dart` → `InputValidator.validateTemperature()`
- **Protection**: Range validation (40°C - 110°C), numeric-only input
- **Use Case**: Sauna temperature controls

### Device ID Validation
- **Location**: `lib/core/utils/security.dart` → `InputValidator.validateDeviceId()`
- **Protection**: UUID format validation
- **Use Case**: Device pairing, API requests

## 2. Output Sanitization

### HTML/XSS Prevention
- **Location**: `lib/core/utils/security.dart` → `InputValidator.sanitizeHtml()`
- **Protection**: Escapes `<`, `>`, `"`, `'`, `/` characters
- **Use Case**: User-generated content display

### Text Sanitization
- **Location**: `lib/core/utils/security.dart` → `DisplayDataSanitizer.sanitizeText()`
- **Protection**: 
  - Removes control characters (0x00-0x1F, 0x7F)
  - Length limits (10,000 chars max)
- **Use Case**: All user-facing text display

### User Content Sanitization
- **Location**: `lib/core/utils/security.dart` → `DisplayDataSanitizer.sanitizeUserContent()`
- **Protection**: 
  - Removes `<script>` tags
  - Removes event handlers (`onclick`, `onerror`, etc.)
  - Removes `javascript:` protocol
- **Use Case**: Comments, notes, device names

## 3. Token Security

### Token Expiry Checking
- **Location**: `lib/core/utils/security.dart` → `TokenSecurity`
- **Features**:
  - `isTokenExpired()`: Check if token is past expiration
  - `isTokenExpiringSoon()`: Check if token expires within 5 minutes
  - `isValidJwtFormat()`: Validate JWT structure (3 parts)
  - `timeUntilExpiry()`: Calculate remaining time

### Token Refresh Flow
- **Location**: `lib/services/api/rest/auth_interceptor.dart`
- **Implementation**:
  1. Validate token format before use
  2. Check expiry status on every request
  3. Automatic refresh if expiring within 5 minutes
  4. Request rejection if token invalid/expired

### Token Storage
- **Location**: `lib/features/auth/data/datasources/auth_local_datasource.dart`
- **Security**: 
  - Uses Hive encrypted box
  - Secure key storage via `flutter_secure_storage`
  - No tokens in logs or error messages

## 4. Text Input Formatters

### Available Formatters
- **Email**: `SecureTextInputFormatters.email` - Allows valid email characters only
- **Numeric**: `SecureTextInputFormatters.numericOnly` - Digits only
- **Temperature**: `SecureTextInputFormatters.temperature` - Digits and minus sign
- **UUID**: `SecureTextInputFormatters.uuid` - Hex digits and dashes
- **No Special Chars**: `SecureTextInputFormatters.noSpecialChars` - Prevents injection

### Usage Example
```dart
TextField(
  inputFormatters: [
    SecureTextInputFormatters.email,
  ],
  validator: InputValidator.validateEmail,
)
```

## 5. Rate Limiting

### Configuration
- **Location**: `lib/services/api/rest/rate_limit_interceptor.dart`
- **Default**: 60 requests per minute
- **Presets**: 
  - Standard: 60/min
  - Aggressive: 30/min
  - Relaxed: 120/min

### Exponential Backoff
- **429 Error Handling**: Automatic retry with backoff
- **Backoff Schedule**: 1s → 2s → 4s → 8s → 16s → 32s (max)
- **Per-Endpoint Tracking**: Separate limits for different API routes

## 6. Security Audit Utility

### Comprehensive Checks
- **Location**: `lib/core/utils/security.dart` → `SecurityAudit.runAudit()`
- **Checks**:
  - Token expiration status
  - Token format validation
  - User input scanning for malicious content
  - Input length validation

### Usage Example
```dart
final result = SecurityAudit.runAudit(
  tokenExpiresAt: session.expiresAt,
  currentToken: session.idToken,
  userInputs: [deviceName, userNote],
);

if (!result.passed) {
  // Handle security issues
  for (final issue in result.issues) {
    print('Security Issue: $issue');
  }
}

if (result.hasWarnings) {
  // Log warnings
  for (final warning in result.warnings) {
    print('Security Warning: $warning');
  }
}
```

## 7. Common Vulnerabilities Addressed

### XSS (Cross-Site Scripting)
- ✅ HTML entity encoding for user content
- ✅ Script tag removal
- ✅ Event handler sanitization
- ✅ `javascript:` protocol blocking

### SQL Injection
- ✅ Using Hive (NoSQL) - not vulnerable to SQL injection
- ✅ GraphQL queries use parameterized variables
- ✅ No raw SQL queries

### Token Theft
- ✅ Tokens stored in encrypted Hive box
- ✅ HTTPS-only API communication
- ✅ Tokens not logged or displayed
- ✅ Automatic token refresh reduces exposure window

### Man-in-the-Middle (MITM)
- ✅ HTTPS enforced via `ApiConstants.baseUrl`
- ✅ Certificate pinning (production recommendation)
- ✅ No sensitive data in URLs

### Denial of Service (DoS)
- ✅ Rate limiting prevents API abuse
- ✅ Input length limits prevent memory exhaustion
- ✅ Timeout configurations on all network requests

## 8. Secure Coding Practices

### Error Handling
- ❌ Never expose stack traces to users
- ❌ Never log sensitive data (tokens, passwords)
- ✅ Use generic error messages for users
- ✅ Detailed logs only in debug mode

### Data Storage
- ✅ Encrypted Hive boxes for sensitive data
- ✅ Secure storage for encryption keys
- ✅ Clear data on logout
- ✅ No sensitive data in shared preferences

### Network Communication
- ✅ HTTPS only
- ✅ Token refresh before expiry
- ✅ Rate limiting on all requests
- ✅ Retry logic with exponential backoff

## 9. Security Checklist

### Before Release
- [ ] Enable certificate pinning for production API
- [ ] Review all `AppLogger` calls to ensure no sensitive data logged
- [ ] Test rate limiting with production API limits
- [ ] Verify HTTPS enforcement in all environments
- [ ] Run security audit on all user inputs
- [ ] Test token refresh flow under poor network conditions
- [ ] Verify encrypted storage working on all platforms
- [ ] Check for exposed API keys in code/config files

### Runtime Monitoring
- [ ] Monitor 429 rate limit errors
- [ ] Track token refresh failures
- [ ] Log authentication failures (without sensitive details)
- [ ] Monitor for unusual input patterns

## 10. Security Contacts

### Reporting Vulnerabilities
- **Email**: security@harvia-app.example.com
- **Process**: Responsible disclosure - 90 day window
- **PGP Key**: [Public key for encrypted reports]

### Security Updates
- **Channel**: GitHub Security Advisories
- **Frequency**: As needed for critical issues
- **Notification**: Email to registered users

## 11. Compliance

### Data Protection
- ✅ GDPR compliant (user data deletion, export)
- ✅ Local-first data storage
- ✅ No analytics without consent
- ✅ Clear privacy policy

### Industry Standards
- ✅ OWASP Mobile Top 10 considerations
- ✅ Flutter security best practices
- ✅ Secure token storage (NIST guidelines)

## 12. Future Enhancements

### Planned Security Features
- [ ] Biometric authentication (Face ID, Touch ID)
- [ ] Certificate pinning for production
- [ ] Security audit logging to secure backend
- [ ] Anomaly detection for unusual device commands
- [ ] Multi-factor authentication support
- [ ] Device trust scoring

---

**Last Updated**: 2024-12-20  
**Version**: 1.0  
**Reviewed By**: Development Team
