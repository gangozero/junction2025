# Authentication Token Fix

## Overview
Fixed critical authentication bug where the wrong JWT token was being used for API authorization.

## Problem
The initial implementation was using the `accessToken` in the Authorization header for API requests, but the Harvia API requires the `idToken` (ID token) instead.

### API Response Format (AWS Cognito)
```json
{
  "idToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh-token-string",
  "expiresIn": 3600
}
```

### Required Authorization Header
```
Authorization: Bearer {{idToken}}
```

## Changes Made

### 1. Updated `TokenResponse` DTO
**File**: `lib/features/auth/data/models/token_response.dart`

- Added `idToken` field
- Updated `fromJson()` to map from camelCase fields (`idToken`, `accessToken`, `refreshToken`, `expiresIn`)
- Removed `user` field (not provided by Cognito auth endpoint)
- Added JWT decoding to extract user ID from `idToken` payload
- Updated `toDomainEntities()` to create session with `idToken`

### 2. Updated `APISession` Entity
**File**: `lib/features/auth/domain/entities/api_session.dart`

- Added `idToken` field (primary token for API authorization)
- Updated constructor, `copyWith()`, and `props`
- Updated `empty()` constructor
- Updated `isEmpty` getter to check `idToken` instead of `accessToken`
- Added documentation clarifying token purposes:
  - `idToken`: For API authorization (used in Bearer header)
  - `accessToken`: For Cognito user pool operations

### 3. Updated `AuthInterceptor`
**File**: `lib/services/api/rest/auth_interceptor.dart`

- Changed Authorization header to use `session.idToken` instead of `session.accessToken`
- Updated 3 locations where auth header is added:
  - Line 47: Token expiring soon case
  - Line 58: Token expired case
  - Line 75: Valid token case

### 4. Updated `AuthLocalDataSource`
**File**: `lib/features/auth/data/datasources/auth_local_datasource.dart`

- Added `_keyIdToken` storage key
- Updated `saveSession()` to store `idToken`
- Updated `getSession()` to retrieve `idToken`
- Updated `clearSession()` to delete `idToken`
- Added `idToken` validation in session retrieval

## Token Usage Guide

### ID Token (idToken)
- **Purpose**: API authorization
- **Usage**: `Authorization: Bearer {{idToken}}`
- **Contains**: User claims (sub, email, cognito:username, etc.)
- **Used for**: All REST API and GraphQL requests

### Access Token (accessToken)
- **Purpose**: Cognito user pool operations
- **Usage**: Cognito-specific APIs (if needed)
- **Contains**: Cognito pool-specific claims
- **Used for**: Potential future Cognito operations

### Refresh Token (refreshToken)
- **Purpose**: Obtaining new ID and access tokens
- **Usage**: POST /auth/refresh endpoint
- **Long-lived**: Typically 30 days
- **Used for**: Token refresh flow

## Authentication Flow

### Login Flow
1. User submits credentials
2. POST /auth/token returns `{idToken, accessToken, refreshToken, expiresIn}`
3. TokenResponse parsed and mapped to APISession + UserAccount
4. idToken extracted and used for Authorization header
5. User ID decoded from idToken JWT payload
6. Tokens stored securely (iOS Keychain / Android Keystore / Web IndexedDB)

### Token Refresh Flow
1. AuthInterceptor detects token expiration (every 55 min)
2. POST /auth/refresh with refreshToken
3. Response: `{idToken, accessToken, expiresIn}`
4. New tokens stored
5. Request retried with new idToken in Authorization header

### Logout Flow
1. POST /auth/revoke with refreshToken
2. Local session cleared (all tokens deleted from secure storage)
3. User redirected to login screen

## Testing Checklist

- [X] Auth models compile without errors
- [X] APISession entity includes idToken field
- [X] Auth interceptor uses idToken for Authorization header
- [X] Local datasource stores/retrieves idToken correctly
- [ ] Login flow end-to-end test
- [ ] Token refresh flow test
- [ ] Logout flow test
- [ ] Verify API requests use correct Authorization header
- [ ] Verify JWT decoding extracts correct user ID

## Migration Notes

### Existing Users
If any test users have existing sessions stored, they will be cleared on the next app launch because the `idToken` field will be missing from secure storage, triggering the incomplete session check.

### No Breaking Changes
This fix is backward compatible for new installations and properly handles the migration for existing users by clearing invalid sessions.

## Related Files
- `lib/features/auth/data/models/token_response.dart`
- `lib/features/auth/domain/entities/api_session.dart`
- `lib/features/auth/data/datasources/auth_local_datasource.dart`
- `lib/services/api/rest/auth_interceptor.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` (unchanged)
- `lib/features/auth/data/repositories/auth_repository_impl.dart` (unchanged)

## API Endpoints Reference

### POST /auth/token
- Returns: `{idToken, accessToken, refreshToken, expiresIn}`
- No user object in response

### POST /auth/refresh  
- Returns: `{idToken, accessToken, expiresIn}`
- No refreshToken in response (use existing one)

### POST /auth/revoke
- Returns: `{success: true}`
- Invalidates refresh token

## Future Enhancements

1. **User Profile Fetching**: After login, fetch full user profile via GraphQL
2. **JWT Validation**: Add client-side JWT signature validation
3. **Token Rotation**: Implement refresh token rotation for enhanced security
4. **Biometric Auth**: Add fingerprint/Face ID for quick re-authentication
