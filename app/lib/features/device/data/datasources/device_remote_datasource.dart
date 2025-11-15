/// Device remote data source using GraphQL
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/api/graphql/graphql_client.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../models/device_dto.dart';
import '../models/sensor_dto.dart';

/// Device remote data source
///
/// Handles GraphQL queries, mutations, and subscriptions for devices and sensors
class DeviceRemoteDataSource {
  final Future<GraphQLClient> Function() _getClient;
  final Future<WebSocketLink> Function() _getWsLink;

  DeviceRemoteDataSource({
    Future<GraphQLClient> Function()? getClient,
    Future<WebSocketLink> Function()? getWsLink,
  }) : _getClient = getClient ?? GraphQLClientService.getClient,
       _getWsLink = getWsLink ?? GraphQLClientService.getWebSocketLink;

  /// Default constructor using GraphQLClientService
  factory DeviceRemoteDataSource.create() {
    return DeviceRemoteDataSource(
      getClient: GraphQLClientService.getClient,
      getWsLink: GraphQLClientService.getWebSocketLink,
    );
  }

  /// List all devices for current user
  ///
  /// GraphQL query: usersDevicesList
  ///
  /// Throws [OperationException] on GraphQL errors.
  Future<List<DeviceDto>> listDevices() async {
    try {
      AppLogger.api('GraphQL', 'usersDevicesList query');

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
          }
        }
      ''';

      final token = await SecureStorageService.getIdToken();
      if (token == null) {
        throw const AuthFailure('No ID token for listDevices');
      }

      final dio = Dio();
      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.graphqlDeviceHttpUrl,
        data: {'query': query},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }

      final responseData = response.data!['data'];
      if (responseData == null) {
        final errors = response.data!['errors'];
        AppLogger.e('GraphQL query returned errors', error: errors);
        throw Exception('GraphQL query failed: $errors');
      }

      final devicesList =
          responseData['usersDevicesList'] as Map<String, dynamic>?;
      final devices = devicesList?['devices'] as List<dynamic>?;

      if (devices == null) {
        AppLogger.w('usersDevicesList returned null devices');
        return [];
      }

      AppLogger.api(
        'GraphQL',
        'usersDevicesList returned ${devices.length} devices',
      );

      return devices
          .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('listDevices failed', error: e);
      rethrow;
    }
  }

  /// Get latest measurements for a device
  ///
  /// GraphQL query: devicesMeasurementsLatest
  ///
  /// Returns a list of measurement data objects parsed from the AWSJSON data field.
  Future<List<Map<String, dynamic>>> getLatestMeasurements(
    String deviceId,
  ) async {
    AppLogger.api('GraphQL', 'devicesMeasurementsLatest query for $deviceId');
    try {
      const query = r'''
        query devicesMeasurementsLatest($deviceId: String!) {
          devicesMeasurementsLatest(deviceId: $deviceId) {
            deviceId
            subId
            timestamp
            sessionId
            type
            data
          }
        }
      ''';

      final token = await SecureStorageService.getIdToken();
      if (token == null) {
        throw const AuthFailure('No ID token for getLatestMeasurements');
      }

      final dio = Dio();
      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.graphqlDataHttpUrl,
        data: {
          'query': query,
          'variables': {'deviceId': deviceId},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to load measurements: ${response.statusCode}');
      }

      final responseData = response.data!['data'];
      if (responseData == null) {
        final errors = response.data!['errors'];
        AppLogger.e('GraphQL query returned errors', error: errors);
        throw Exception('GraphQL query failed: $errors');
      }

      AppLogger.d(
        'Raw measurement response for $deviceId: ${jsonEncode(responseData)}',
      );

      final latestMeasurements =
          responseData['devicesMeasurementsLatest'] as List<dynamic>?;

      if (latestMeasurements == null || latestMeasurements.isEmpty) {
        AppLogger.w('devicesMeasurementsLatest returned null or empty');
        return [];
      }

      // Parse the measurement items and extract data from the JSON strings
      final parsedMeasurements = <Map<String, dynamic>>[];

      for (final item in latestMeasurements) {
        final measurementItem = item as Map<String, dynamic>;
        final dataJson = measurementItem['data'] as String?;

        if (dataJson != null && dataJson.isNotEmpty) {
          try {
            // The 'data' field is an AWSJSON string, parse it
            final parsedData = jsonDecode(dataJson) as Map<String, dynamic>;
            // Add metadata from the measurement item
            parsedMeasurements.add({
              ...parsedData,
              '_deviceId': measurementItem['deviceId'],
              '_subId': measurementItem['subId'],
              '_timestamp': measurementItem['timestamp'],
              '_type': measurementItem['type'],
            });
          } catch (e) {
            AppLogger.w('Failed to parse data JSON for measurement: $e');
          }
        }
      }

      AppLogger.d(
        'Parsed ${parsedMeasurements.length} measurements for $deviceId',
      );

      return parsedMeasurements;
    } catch (e) {
      AppLogger.e('getLatestMeasurements failed for $deviceId', error: e);
      // Return empty list on failure to not break the UI for a single device
      return [];
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

      final client = await _getClient();
      final result = await client.query(
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

      final client = await _getClient();
      final result = await client.query(
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

      final client = await _getClient();
      final result = await client.query(
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
