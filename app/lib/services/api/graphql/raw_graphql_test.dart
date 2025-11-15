/// Test raw GraphQL request with Dio
library;

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/logger.dart';
import '../../storage/secure_storage_service.dart';

/// Test raw GraphQL query using Dio (bypassing graphql_flutter)
Future<void> testRawGraphQLQuery() async {
  try {
    // Get token
    final token = await SecureStorageService.getIdToken();
    if (token == null) {
      AppLogger.e('No ID token available');
      return;
    }

    AppLogger.i('Testing raw GraphQL query with Dio');
    AppLogger.d('Token (first 20): ${token.substring(0, 20)}...');

    final endpoint = ApiConstants.getGraphqlHttpUrl();
    AppLogger.d('Endpoint: $endpoint');

    // Create Dio instance
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    // GraphQL query
    const query = r'''
      query ListMyDevices {
        usersDevicesList {
          devices {
            id
            type
            attr {
              key
              value
            }
          }
          nextToken
        }
      }
    ''';

    AppLogger.d('Sending GraphQL query...');

    // Make request
    final response = await dio.post<Map<String, dynamic>>(
      endpoint,
      data: {'query': query},
    );

    AppLogger.i('Response status: ${response.statusCode}');
    AppLogger.i('Response data: ${response.data}');

    if (response.data?['data'] != null) {
      final devicesList = response.data!['data']['usersDevicesList'];
      final devices = devicesList['devices'] as List;
      AppLogger.i('✅ SUCCESS! Found ${devices.length} devices');

      for (final device in devices) {
        AppLogger.d('Device: ${device['id']} (${device['type']})');
      }
    } else if (response.data?['errors'] != null) {
      AppLogger.e('GraphQL errors: ${response.data!['errors']}');
    }
  } catch (e, stackTrace) {
    AppLogger.e('Raw GraphQL test failed', error: e, stackTrace: stackTrace);
  }
}
