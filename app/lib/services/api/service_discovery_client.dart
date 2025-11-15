/// Service discovery API client
library;

import 'package:dio/dio.dart';

import '../../core/config/endpoint_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

/// Client for fetching dynamic endpoints from service discovery
class ServiceDiscoveryClient {
  final Dio _dio;

  ServiceDiscoveryClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  /// Fetch current endpoints from service discovery
  Future<EndpointConfig> fetchEndpoints() async {
    try {
      AppLogger.i('Fetching endpoints from service discovery');

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.serviceDiscoveryUrl,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Service discovery failed with status ${response.statusCode}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final endpoints = data['endpoints'] as Map<String, dynamic>;

      // Parse response according to API structure
      final config = EndpointConfig(
        restApi: RestApiEndpoints(
          generics: HttpsEndpoint(
            https: endpoints['RestApi']['generics']['https'] as String,
          ),
          device: HttpsEndpoint(
            https: endpoints['RestApi']['device']['https'] as String,
          ),
          data: HttpsEndpoint(
            https: endpoints['RestApi']['data']['https'] as String,
          ),
          users: endpoints['RestApi']['users'] != null
              ? HttpsEndpoint(
                  https: endpoints['RestApi']['users']['https'] as String,
                )
              : null,
        ),
        graphQL: GraphQLEndpoints(
          device: GraphQLEndpoint(
            https: endpoints['GraphQL']['device']['https'] as String,
            wss: endpoints['GraphQL']['device']['wss'] as String,
          ),
          data: GraphQLEndpoint(
            https: endpoints['GraphQL']['data']['https'] as String,
            wss: endpoints['GraphQL']['data']['wss'] as String,
          ),
          events: GraphQLEndpoint(
            https: endpoints['GraphQL']['events']['https'] as String,
            wss: endpoints['GraphQL']['events']['wss'] as String,
          ),
        ),
      );

      AppLogger.i('Successfully fetched endpoints');
      return config;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to fetch endpoints from service discovery',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
