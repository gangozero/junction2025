/// Endpoint provider with Riverpod
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/endpoint_config.dart';
import '../../core/config/endpoint_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import 'service_discovery_client.dart';

part 'endpoint_provider.g.dart';

/// Provider for endpoint repository
@riverpod
EndpointRepository endpointRepository(EndpointRepositoryRef ref) {
  final repository = EndpointRepository();
  repository.initialize();
  return repository;
}

/// Provider for service discovery client
@riverpod
ServiceDiscoveryClient serviceDiscoveryClient(ServiceDiscoveryClientRef ref) {
  return ServiceDiscoveryClient();
}

/// Provider for current endpoint configuration
@riverpod
class EndpointConfigNotifier extends _$EndpointConfigNotifier {
  @override
  Future<EndpointConfig> build() async {
    return await _loadEndpoints();
  }

  /// Load endpoints from cache or service discovery
  Future<EndpointConfig> _loadEndpoints() async {
    final repository = ref.read(endpointRepositoryProvider);
    final client = ref.read(serviceDiscoveryClientProvider);

    try {
      // Check cache first
      final cached = repository.getConfig();
      if (cached != null && repository.isCacheFresh()) {
        AppLogger.i('Using cached endpoints');
        return cached;
      }

      // Fetch from service discovery
      AppLogger.i('Fetching fresh endpoints from service discovery');
      final config = await client.fetchEndpoints();

      // Save to cache
      await repository.saveConfig(config);

      return config;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to load endpoints, falling back to hardcoded values',
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback to hardcoded endpoints
      return _getFallbackConfig();
    }
  }

  /// Refresh endpoints from service discovery
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    final repository = ref.read(endpointRepositoryProvider);
    final client = ref.read(serviceDiscoveryClientProvider);

    state = await AsyncValue.guard(() async {
      final config = await client.fetchEndpoints();
      await repository.saveConfig(config);
      AppLogger.i('Endpoints refreshed successfully');
      return config;
    });

    if (state.hasError) {
      AppLogger.e(
        'Failed to refresh endpoints',
        error: state.error,
        stackTrace: state.stackTrace,
      );
    }
  }

  /// Get fallback configuration using hardcoded endpoints
  EndpointConfig _getFallbackConfig() {
    return EndpointConfig(
      restApi: RestApiEndpoints(
        generics: HttpsEndpoint(https: ApiConstants.restGenericsBaseUrl),
        device: HttpsEndpoint(https: ApiConstants.restDeviceBaseUrl),
        data: HttpsEndpoint(https: ApiConstants.restDataBaseUrl),
        users: HttpsEndpoint(https: ApiConstants.restUsersBaseUrl),
      ),
      graphQL: GraphQLEndpoints(
        device: GraphQLEndpoint(
          https: ApiConstants.graphqlDeviceHttpUrl,
          wss: ApiConstants.graphqlDeviceWsUrl,
        ),
        data: GraphQLEndpoint(
          https: ApiConstants.graphqlDataHttpUrl,
          wss: ApiConstants.graphqlDataWsUrl,
        ),
        events: GraphQLEndpoint(
          https: ApiConstants.graphqlEventsHttpUrl,
          wss: ApiConstants.graphqlEventsWsUrl,
        ),
      ),
    );
  }
}

/// Helper providers for specific endpoint types

/// REST API - Generics (Authentication) endpoint
@riverpod
String restGenericsUrl(RestGenericsUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.restApi.generics.https,
    loading: () => ApiConstants.restGenericsBaseUrl,
    error: (_, __) => ApiConstants.restGenericsBaseUrl,
  );
}

/// REST API - Device endpoint
@riverpod
String restDeviceUrl(RestDeviceUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.restApi.device.https,
    loading: () => ApiConstants.restDeviceBaseUrl,
    error: (_, __) => ApiConstants.restDeviceBaseUrl,
  );
}

/// REST API - Data endpoint
@riverpod
String restDataUrl(RestDataUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.restApi.data.https,
    loading: () => ApiConstants.restDataBaseUrl,
    error: (_, __) => ApiConstants.restDataBaseUrl,
  );
}

/// GraphQL - Device HTTPS endpoint
@riverpod
String graphqlDeviceHttpUrl(GraphqlDeviceHttpUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.graphQL.device.https,
    loading: () => ApiConstants.graphqlDeviceHttpUrl,
    error: (_, __) => ApiConstants.graphqlDeviceHttpUrl,
  );
}

/// GraphQL - Device WebSocket endpoint
@riverpod
String graphqlDeviceWsUrl(GraphqlDeviceWsUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.graphQL.device.wss,
    loading: () => ApiConstants.graphqlDeviceWsUrl,
    error: (_, __) => ApiConstants.graphqlDeviceWsUrl,
  );
}

/// GraphQL - Data HTTPS endpoint
@riverpod
String graphqlDataHttpUrl(GraphqlDataHttpUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.graphQL.data.https,
    loading: () => ApiConstants.graphqlDataHttpUrl,
    error: (_, __) => ApiConstants.graphqlDataHttpUrl,
  );
}

/// GraphQL - Data WebSocket endpoint
@riverpod
String graphqlDataWsUrl(GraphqlDataWsUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.graphQL.data.wss,
    loading: () => ApiConstants.graphqlDataWsUrl,
    error: (_, __) => ApiConstants.graphqlDataWsUrl,
  );
}

/// GraphQL - Events HTTPS endpoint
@riverpod
String graphqlEventsHttpUrl(GraphqlEventsHttpUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.graphQL.events.https,
    loading: () => ApiConstants.graphqlEventsHttpUrl,
    error: (_, __) => ApiConstants.graphqlEventsHttpUrl,
  );
}

/// GraphQL - Events WebSocket endpoint
@riverpod
String graphqlEventsWsUrl(GraphqlEventsWsUrlRef ref) {
  final config = ref.watch(endpointConfigNotifierProvider);
  return config.when(
    data: (endpoints) => endpoints.graphQL.events.wss,
    loading: () => ApiConstants.graphqlEventsWsUrl,
    error: (_, __) => ApiConstants.graphqlEventsWsUrl,
  );
}
