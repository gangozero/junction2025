/// GraphQL Client Configuration for Harvia MSGA
///
/// Configures GraphQL client with WebSocket support for subscriptions,
/// auto-reconnection, and authentication handling
library;

import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/logger.dart';
import '../../storage/secure_storage_service.dart';

/// GraphQL client service
///
/// Manages GraphQL HTTP and WebSocket connections with authentication
class GraphQLClientService {
  GraphQLClientService._();

  static GraphQLClient? _client;
  static WebSocketLink? _wsLink;

  /// Get GraphQL client instance
  ///
  /// Initializes client on first access with auth token
  static Future<GraphQLClient> getClient() async {
    if (_client != null) return _client!;

    AppLogger.i('Initializing GraphQL client');

    final httpLink = HttpLink(ApiConstants.getGraphqlHttpUrl());

    final authLink = AuthLink(
      getToken: () async {
        final token = await SecureStorageService.getAccessToken();
        if (token != null) {
          AppLogger.d('Adding auth token to GraphQL request');
          return ApiConstants.getAuthHeader(token);
        }
        return null;
      },
    );

    final link = authLink.concat(httpLink);

    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.mergeOptimistic,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
      ),
    );

    AppLogger.i('GraphQL client initialized');
    return _client!;
  }

  /// Get WebSocket link for subscriptions
  ///
  /// Creates authenticated WebSocket connection with auto-reconnect
  static Future<WebSocketLink> getWebSocketLink() async {
    if (_wsLink != null) return _wsLink!;

    AppLogger.i('Initializing GraphQL WebSocket link');

    _wsLink = WebSocketLink(
      ApiConstants.getGraphqlWsUrl(),
      config: SocketClientConfig(
        autoReconnect: true,
        initialPayload: () async {
          final currentToken = await SecureStorageService.getAccessToken();
          return {
            'headers': {
              'Authorization': currentToken != null
                  ? ApiConstants.getAuthHeader(currentToken)
                  : null,
            },
          };
        },
        inactivityTimeout: const Duration(
          milliseconds: ApiConstants.wsPingInterval,
        ),
      ),
    );

    AppLogger.i('GraphQL WebSocket link initialized');
    return _wsLink!;
  }

  /// Execute GraphQL query
  ///
  /// Returns query result or throws GraphQLFailure
  static Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
  }) async {
    try {
      final client = await getClient();

      AppLogger.graphql(
        query.split('\n').first.trim(),
        'Query',
        variables: variables,
      );

      final result = await client.query(
        QueryOptions(
          document: gql(query),
          variables: variables ?? {},
          fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.e('GraphQL query error', error: result.exception);
        throw _handleException(result.exception!);
      }

      AppLogger.d('GraphQL query successful');
      return result;
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.e('GraphQL query failed', error: e);
      throw GraphQLFailure('Query failed: $e');
    }
  }

  /// Execute GraphQL mutation
  ///
  /// Returns mutation result or throws GraphQLFailure
  static Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      final client = await getClient();

      AppLogger.graphql(
        mutation.split('\n').first.trim(),
        'Mutation',
        variables: variables,
      );

      final result = await client.mutate(
        MutationOptions(document: gql(mutation), variables: variables ?? {}),
      );

      if (result.hasException) {
        AppLogger.e('GraphQL mutation error', error: result.exception);
        throw _handleException(result.exception!);
      }

      AppLogger.d('GraphQL mutation successful');
      return result;
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.e('GraphQL mutation failed', error: e);
      throw GraphQLFailure('Mutation failed: $e');
    }
  }

  /// Subscribe to GraphQL subscription
  ///
  /// Returns stream of subscription results
  static Future<Stream<QueryResult>> subscribe(
    String subscription, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      final wsLink = await getWebSocketLink();
      final authLink = AuthLink(
        getToken: () async {
          final token = await SecureStorageService.getAccessToken();
          return token != null ? ApiConstants.getAuthHeader(token) : null;
        },
      );

      final link = authLink.concat(wsLink);

      final client = GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      AppLogger.graphql(
        subscription.split('\n').first.trim(),
        'Subscription',
        variables: variables,
      );

      final stream = client.subscribe(
        SubscriptionOptions(
          document: gql(subscription),
          variables: variables ?? {},
        ),
      );

      AppLogger.i('GraphQL subscription established');
      return stream;
    } catch (e) {
      AppLogger.e('GraphQL subscription failed', error: e);
      throw GraphQLFailure('Subscription failed: $e');
    }
  }

  /// Handle GraphQL exception
  ///
  /// Converts OperationException to appropriate Failure
  static Failure _handleException(OperationException exception) {
    // Check for network errors
    if (exception.linkException != null) {
      final linkException = exception.linkException!;

      if (linkException is NetworkException) {
        return const NetworkFailure('No internet connection');
      }

      if (linkException is ServerException) {
        return ServerFailure(
          linkException.parsedResponse?.errors?.first.message,
          linkException.statusCode,
        );
      }

      if (linkException is HttpLinkServerException) {
        return ServerFailure(
          linkException.parsedResponse?.errors?.first.message,
          linkException.response.statusCode,
        );
      }
    }

    // Check for GraphQL errors
    if (exception.graphqlErrors.isNotEmpty) {
      final errors = exception.graphqlErrors.map((e) => e.message).toList();
      final firstError = exception.graphqlErrors.first;

      // Check for authentication errors
      if (firstError.extensions?['code'] == 'UNAUTHENTICATED') {
        return const AuthFailure(
          'Authentication required',
          AuthFailureReason.unauthorized,
        );
      }

      return GraphQLFailure(firstError.message, errors);
    }

    return GraphQLFailure(exception.toString());
  }

  /// Reset client (useful after logout)
  static void reset() {
    AppLogger.i('Resetting GraphQL client');
    _client = null;
    _wsLink?.dispose();
    _wsLink = null;
  }

  /// Dispose resources
  static void dispose() {
    AppLogger.d('Disposing GraphQL client');
    _wsLink?.dispose();
    _wsLink = null;
    _client = null;
  }
}
