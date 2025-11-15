/// Endpoint configuration model
library;

/// Complete endpoint configuration from service discovery
class EndpointConfig {
  final RestApiEndpoints restApi;
  final GraphQLEndpoints graphQL;

  const EndpointConfig({required this.restApi, required this.graphQL});

  factory EndpointConfig.fromJson(Map<String, dynamic> json) {
    return EndpointConfig(
      restApi: RestApiEndpoints.fromJson(
        json['RestApi'] as Map<String, dynamic>,
      ),
      graphQL: GraphQLEndpoints.fromJson(
        json['GraphQL'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'RestApi': restApi.toJson(), 'GraphQL': graphQL.toJson()};
  }
}

/// REST API endpoints grouped by service
class RestApiEndpoints {
  final HttpsEndpoint generics;
  final HttpsEndpoint device;
  final HttpsEndpoint data;
  final HttpsEndpoint? users;

  const RestApiEndpoints({
    required this.generics,
    required this.device,
    required this.data,
    this.users,
  });

  factory RestApiEndpoints.fromJson(Map<String, dynamic> json) {
    return RestApiEndpoints(
      generics: HttpsEndpoint.fromJson(
        json['generics'] as Map<String, dynamic>,
      ),
      device: HttpsEndpoint.fromJson(json['device'] as Map<String, dynamic>),
      data: HttpsEndpoint.fromJson(json['data'] as Map<String, dynamic>),
      users: json['users'] != null
          ? HttpsEndpoint.fromJson(json['users'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generics': generics.toJson(),
      'device': device.toJson(),
      'data': data.toJson(),
      if (users != null) 'users': users!.toJson(),
    };
  }
}

/// GraphQL endpoints with HTTPS and WebSocket
class GraphQLEndpoints {
  final GraphQLEndpoint device;
  final GraphQLEndpoint data;
  final GraphQLEndpoint events;

  const GraphQLEndpoints({
    required this.device,
    required this.data,
    required this.events,
  });

  factory GraphQLEndpoints.fromJson(Map<String, dynamic> json) {
    return GraphQLEndpoints(
      device: GraphQLEndpoint.fromJson(json['device'] as Map<String, dynamic>),
      data: GraphQLEndpoint.fromJson(json['data'] as Map<String, dynamic>),
      events: GraphQLEndpoint.fromJson(json['events'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'data': data.toJson(),
      'events': events.toJson(),
    };
  }
}

/// Single HTTPS endpoint
class HttpsEndpoint {
  final String https;

  const HttpsEndpoint({required this.https});

  factory HttpsEndpoint.fromJson(Map<String, dynamic> json) {
    return HttpsEndpoint(https: json['https'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'https': https};
  }
}

/// GraphQL endpoint with HTTPS and WebSocket URLs
class GraphQLEndpoint {
  final String https;
  final String wss;

  const GraphQLEndpoint({required this.https, required this.wss});

  factory GraphQLEndpoint.fromJson(Map<String, dynamic> json) {
    return GraphQLEndpoint(
      https: json['https'] as String,
      wss: json['wss'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'https': https, 'wss': wss};
  }
}
