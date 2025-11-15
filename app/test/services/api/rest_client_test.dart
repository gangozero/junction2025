/// Tests for REST client URL type mapping
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:harvia_msga/services/api/rest/rest_client.dart';

void main() {
  group('RestApiClient URL Type Mapping', () {
    test('RestApiService enum should have all required types', () {
      // Verify all expected service types exist
      expect(RestApiService.values.length, equals(4));
      expect(RestApiService.values, contains(RestApiService.generics));
      expect(RestApiService.values, contains(RestApiService.device));
      expect(RestApiService.values, contains(RestApiService.data));
      expect(RestApiService.values, contains(RestApiService.users));
    });

    test('getDio should return different instances for different services', () {
      // Each service should have its own Dio instance
      final genericsDio = RestApiClient.getDio(RestApiService.generics);
      final deviceDio = RestApiClient.getDio(RestApiService.device);
      final dataDio = RestApiClient.getDio(RestApiService.data);
      final usersDio = RestApiClient.getDio(RestApiService.users);

      // All should be non-null
      expect(genericsDio, isNotNull);
      expect(deviceDio, isNotNull);
      expect(dataDio, isNotNull);
      expect(usersDio, isNotNull);

      // Calling again should return the same instance (singleton per service)
      expect(RestApiClient.getDio(RestApiService.generics), same(genericsDio));
      expect(RestApiClient.getDio(RestApiService.device), same(deviceDio));
      expect(RestApiClient.getDio(RestApiService.data), same(dataDio));
      expect(RestApiClient.getDio(RestApiService.users), same(usersDio));
    });

    test('reset should clear all service clients', () {
      // Create clients for all services
      final genericsDio1 = RestApiClient.getDio(RestApiService.generics);
      final deviceDio1 = RestApiClient.getDio(RestApiService.device);

      // Reset
      RestApiClient.reset();

      // New calls should create new instances
      final genericsDio2 = RestApiClient.getDio(RestApiService.generics);
      final deviceDio2 = RestApiClient.getDio(RestApiService.device);

      expect(genericsDio2, isNot(same(genericsDio1)));
      expect(deviceDio2, isNot(same(deviceDio1)));
    });

    test('default service should be generics', () {
      // Reset to ensure clean state
      RestApiClient.reset();

      // Calling without parameter should use generics
      final defaultDio = RestApiClient.getDio();
      final genericsDio = RestApiClient.getDio(RestApiService.generics);

      expect(defaultDio, same(genericsDio));
    });
  });
}
