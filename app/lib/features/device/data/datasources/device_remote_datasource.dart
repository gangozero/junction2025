/// Device remote data source using GraphQL
library;

import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../../../services/api/graphql/graphql_client.dart';
import '../models/device_dto.dart';
import '../models/sensor_dto.dart';

/// Device remote data source
///
/// Handles GraphQL queries, mutations, and subscriptions for devices and sensors
class DeviceRemoteDataSource {
  final GraphQLClient Function() _getClient;
  final Future<WebSocketLink> Function() _getWsLink;

  DeviceRemoteDataSource({
    GraphQLClient Function()? getClient,
    Future<WebSocketLink> Function()? getWsLink,
  }) : _getClient = getClient ?? (() => throw UnimplementedError()),
       _getWsLink = getWsLink ?? (() => throw UnimplementedError());

  /// Default constructor using GraphQLClientService
  factory DeviceRemoteDataSource.create() {
    return DeviceRemoteDataSource(
      getClient: () {
        // Synchronous wrapper - client should be pre-initialized
        return GraphQLClientService.getClient() as GraphQLClient;
      },
      getWsLink: GraphQLClientService.getWebSocketLink,
    );
  }

  /// List all devices for current user
  ///
  /// GraphQL query: listDevices
  ///
  /// Throws [OperationException] on GraphQL errors.
  Future<List<DeviceDto>> listDevices() async {
    try {
      AppLogger.api('GraphQL', 'listDevices query');

      const query = r'''
        query ListDevices {
          listDevices {
            id
            name
            modelNumber
            serialNumber
            powerState
            heatingStatus
            connectionStatus
            currentTemperature
            targetTemperature
            minTemperature
            maxTemperature
            lastUpdated
            linkedSensorIds
          }
        }
      ''';

      final result = await _getClient().query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.e('listDevices query failed', error: result.exception);
        throw result.exception!;
      }

      final data = result.data?['listDevices'] as List<dynamic>?;
      if (data == null) {
        AppLogger.w('listDevices returned null data');
        return [];
      }

      AppLogger.api('GraphQL', 'listDevices returned ${data.length} devices');

      return data
          .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('listDevices failed', error: e);
      rethrow;
    }
  }

  /// Get device state
  ///
  /// GraphQL query: getDeviceState(deviceId)
  ///
  /// Throws [OperationException] on GraphQL errors.
  Future<DeviceDto> getDeviceState(String deviceId) async {
    try {
      AppLogger.api('GraphQL', 'getDeviceState query for $deviceId');

      const query = r'''
        query GetDeviceState($deviceId: ID!) {
          getDeviceState(deviceId: $deviceId) {
            id
            name
            modelNumber
            serialNumber
            powerState
            heatingStatus
            connectionStatus
            currentTemperature
            targetTemperature
            minTemperature
            maxTemperature
            lastUpdated
            linkedSensorIds
          }
        }
      ''';

      final result = await _getClient().query(
        QueryOptions(
          document: gql(query),
          variables: {'deviceId': deviceId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.e('getDeviceState query failed', error: result.exception);
        throw result.exception!;
      }

      final data = result.data?['getDeviceState'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Device not found: $deviceId');
      }

      AppLogger.api('GraphQL', 'getDeviceState returned device $deviceId');

      return DeviceDto.fromJson(data);
    } catch (e) {
      AppLogger.e('getDeviceState failed for $deviceId', error: e);
      rethrow;
    }
  }

  /// Subscribe to device state changes
  ///
  /// GraphQL subscription: onDeviceStateChange(deviceId)
  ///
  /// Returns a stream of device state updates.
  Stream<DeviceDto> subscribeToDeviceState(String deviceId) async* {
    try {
      AppLogger.api('GraphQL', 'Subscribing to device state: $deviceId');

      const subscription = r'''
        subscription OnDeviceStateChange($deviceId: ID!) {
          onDeviceStateChange(deviceId: $deviceId) {
            id
            name
            modelNumber
            serialNumber
            powerState
            heatingStatus
            connectionStatus
            currentTemperature
            targetTemperature
            minTemperature
            maxTemperature
            lastUpdated
            linkedSensorIds
          }
        }
      ''';

      final wsLink = await _getWsLink();
      final client = GraphQLClient(
        link: wsLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final stream = client.subscribe(
        SubscriptionOptions(
          document: gql(subscription),
          variables: {'deviceId': deviceId},
        ),
      );

      await for (final result in stream) {
        if (result.hasException) {
          AppLogger.e(
            'Device state subscription error',
            error: result.exception,
          );
          throw result.exception!;
        }

        final data =
            result.data?['onDeviceStateChange'] as Map<String, dynamic>?;
        if (data != null) {
          AppLogger.d('Device state update received for $deviceId');
          yield DeviceDto.fromJson(data);
        }
      }
    } catch (e) {
      AppLogger.e('Device state subscription failed for $deviceId', error: e);
      rethrow;
    }
  }

  /// List sensors for a controller
  ///
  /// GraphQL query: listSensors(controllerId)
  ///
  /// Throws [OperationException] on GraphQL errors.
  Future<List<SensorDto>> listSensors(String controllerId) async {
    try {
      AppLogger.api('GraphQL', 'listSensors query for $controllerId');

      const query = r'''
        query ListSensors($controllerId: ID!) {
          listSensors(controllerId: $controllerId) {
            id
            name
            type
            linkedControllerId
            temperature
            humidity
            batteryLevel
            lastUpdated
            isOnline
          }
        }
      ''';

      final result = await _getClient().query(
        QueryOptions(
          document: gql(query),
          variables: {'controllerId': controllerId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.e('listSensors query failed', error: result.exception);
        throw result.exception!;
      }

      final data = result.data?['listSensors'] as List<dynamic>?;
      if (data == null) {
        AppLogger.w('listSensors returned null data');
        return [];
      }

      AppLogger.api('GraphQL', 'listSensors returned ${data.length} sensors');

      return data
          .map((e) => SensorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('listSensors failed', error: e);
      rethrow;
    }
  }

  /// Get latest sensor data
  ///
  /// GraphQL query: getLatestData(sensorId)
  ///
  /// Throws [OperationException] on GraphQL errors.
  Future<SensorDto> getLatestData(String sensorId) async {
    try {
      AppLogger.api('GraphQL', 'getLatestData query for $sensorId');

      const query = r'''
        query GetLatestData($sensorId: ID!) {
          getLatestData(sensorId: $sensorId) {
            id
            name
            type
            linkedControllerId
            temperature
            humidity
            batteryLevel
            lastUpdated
            isOnline
          }
        }
      ''';

      final result = await _getClient().query(
        QueryOptions(
          document: gql(query),
          variables: {'sensorId': sensorId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        AppLogger.e('getLatestData query failed', error: result.exception);
        throw result.exception!;
      }

      final data = result.data?['getLatestData'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Sensor not found: $sensorId');
      }

      AppLogger.api('GraphQL', 'getLatestData returned sensor $sensorId');

      return SensorDto.fromJson(data);
    } catch (e) {
      AppLogger.e('getLatestData failed for $sensorId', error: e);
      rethrow;
    }
  }

  /// Subscribe to sensor data updates
  ///
  /// GraphQL subscription: onSensorData(sensorId)
  ///
  /// Returns a stream of sensor data updates.
  Stream<SensorDto> subscribeToSensorData(String sensorId) async* {
    try {
      AppLogger.api('GraphQL', 'Subscribing to sensor data: $sensorId');

      const subscription = r'''
        subscription OnSensorData($sensorId: ID!) {
          onSensorData(sensorId: $sensorId) {
            id
            name
            type
            linkedControllerId
            temperature
            humidity
            batteryLevel
            lastUpdated
            isOnline
          }
        }
      ''';

      final wsLink = await _getWsLink();
      final client = GraphQLClient(
        link: wsLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final stream = client.subscribe(
        SubscriptionOptions(
          document: gql(subscription),
          variables: {'sensorId': sensorId},
        ),
      );

      await for (final result in stream) {
        if (result.hasException) {
          AppLogger.e(
            'Sensor data subscription error',
            error: result.exception,
          );
          throw result.exception!;
        }

        final data = result.data?['onSensorData'] as Map<String, dynamic>?;
        if (data != null) {
          AppLogger.d('Sensor data update received for $sensorId');
          yield SensorDto.fromJson(data);
        }
      }
    } catch (e) {
      AppLogger.e('Sensor data subscription failed for $sensorId', error: e);
      rethrow;
    }
  }
}
