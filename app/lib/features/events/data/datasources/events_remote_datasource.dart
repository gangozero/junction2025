/// Events remote data source (GraphQL)
library;

import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../services/api/graphql/graphql_client.dart';
import '../models/event_dto.dart';

/// Events remote data source
///
/// Handles GraphQL queries and subscriptions for events
class EventsRemoteDataSource {
  final GraphQLClient client;

  const EventsRemoteDataSource({required this.client});

  /// Factory constructor using GraphQL client service
  factory EventsRemoteDataSource.create() {
    return EventsRemoteDataSource(
      client: GraphQLClientService.getClient() as GraphQLClient,
    );
  }

  /// List events with filters
  Future<List<EventDTO>> listEvents({
    String? deviceId,
    List<String>? types,
    List<String>? severities,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    const query = '''
      query ListEvents(
        \$deviceId: ID
        \$types: [EventType!]
        \$severities: [Severity!]
        \$startDate: DateTime
        \$endDate: DateTime
        \$limit: Int
        \$offset: Int
      ) {
        listEvents(
          deviceId: \$deviceId
          types: \$types
          severities: \$severities
          startDate: \$startDate
          endDate: \$endDate
          limit: \$limit
          offset: \$offset
        ) {
          eventId
          deviceId
          type
          severity
          title
          message
          timestamp
          metadata
          acknowledged
          acknowledgedAt
        }
      }
    ''';

    final variables = <String, dynamic>{
      if (deviceId != null) 'deviceId': deviceId,
      if (types != null && types.isNotEmpty) 'types': types,
      if (severities != null && severities.isNotEmpty) 'severities': severities,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final eventsData = result.data?['listEvents'] as List<dynamic>?;
    if (eventsData == null) {
      throw Exception('No events data in response');
    }

    return eventsData
        .map((e) => EventDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Subscribe to real-time events
  Stream<EventDTO> subscribeToEvents({String? deviceId}) {
    const subscription = '''
      subscription OnEvent(\$deviceId: ID) {
        onEvent(deviceId: \$deviceId) {
          eventId
          deviceId
          type
          severity
          title
          message
          timestamp
          metadata
          acknowledged
          acknowledgedAt
        }
      }
    ''';

    final variables = <String, dynamic>{
      if (deviceId != null) 'deviceId': deviceId,
    };

    return client
        .subscribe(
          SubscriptionOptions(
            document: gql(subscription),
            variables: variables,
          ),
        )
        .map((result) {
          if (result.hasException) {
            throw result.exception!;
          }

          final eventData = result.data?['onEvent'] as Map<String, dynamic>?;
          if (eventData == null) {
            throw Exception('No event data in subscription');
          }

          return EventDTO.fromJson(eventData);
        });
  }

  /// Acknowledge an event
  Future<EventDTO> acknowledgeEvent(String eventId) async {
    const mutation = '''
      mutation AcknowledgeEvent(\$eventId: ID!) {
        acknowledgeEvent(eventId: \$eventId) {
          eventId
          deviceId
          type
          severity
          title
          message
          timestamp
          metadata
          acknowledged
          acknowledgedAt
        }
      }
    ''';

    final result = await client.mutate(
      MutationOptions(document: gql(mutation), variables: {'eventId': eventId}),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final eventData = result.data?['acknowledgeEvent'] as Map<String, dynamic>?;
    if (eventData == null) {
      throw Exception('No event data in response');
    }

    return EventDTO.fromJson(eventData);
  }

  /// Get unacknowledged events count
  Future<int> getUnacknowledgedCount({String? deviceId}) async {
    const query = '''
      query GetUnacknowledgedCount(\$deviceId: ID) {
        unacknowledgedEventsCount(deviceId: \$deviceId)
      }
    ''';

    final variables = <String, dynamic>{
      if (deviceId != null) 'deviceId': deviceId,
    };

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['unacknowledgedEventsCount'] as int? ?? 0;
  }
}
