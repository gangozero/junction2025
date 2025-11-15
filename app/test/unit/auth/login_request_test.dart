/// Tests for LoginRequest model
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:harvia_msga/features/auth/data/models/login_request.dart';

void main() {
  group('LoginRequest', () {
    test('toJson should use "username" field instead of "email"', () {
      // Arrange
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      // Act
      final json = request.toJson();

      // Assert - Must match Python API format: {"username": ..., "password": ...}
      expect(json['username'], equals('test@example.com'));
      expect(json['password'], equals('password123'));
      expect(json.containsKey('email'), isFalse);
    });

    test('toJson should include optional device fields', () {
      // Arrange
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
        deviceId: 'device-123',
        deviceName: 'Test Device',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['username'], equals('test@example.com'));
      expect(json['password'], equals('password123'));
      expect(json['device_id'], equals('device-123'));
      expect(json['device_name'], equals('Test Device'));
    });

    test('toJson should omit null device fields', () {
      // Arrange
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json.containsKey('device_id'), isFalse);
      expect(json.containsKey('device_name'), isFalse);
    });
  });
}
