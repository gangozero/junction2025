/// Device local data source using Hive
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/sauna_controller.dart';
import '../../domain/entities/sensor_device.dart';

/// Device local data source
///
/// Handles caching of device and sensor data using Hive
class DeviceLocalDataSource {
  static const String _devicesBox = 'devices';
  static const String _sensorsBox = 'sensors';

  /// Get devices box
  Future<Box<dynamic>> _getDevicesBox() async {
    if (!Hive.isBoxOpen(_devicesBox)) {
      return await Hive.openBox(_devicesBox);
    }
    return Hive.box(_devicesBox);
  }

  /// Get sensors box
  Future<Box<dynamic>> _getSensorsBox() async {
    if (!Hive.isBoxOpen(_sensorsBox)) {
      return await Hive.openBox(_sensorsBox);
    }
    return Hive.box(_sensorsBox);
  }

  /// Save device to cache
  ///
  /// Throws [Exception] if storage operation fails.
  Future<void> saveDevice(SaunaController device) async {
    try {
      final box = await _getDevicesBox();
      final data = _deviceToMap(device);
      await box.put(device.deviceId, data);
      AppLogger.cache('save', device.deviceId);
    } catch (e) {
      AppLogger.e('Failed to cache device', error: e);
      rethrow;
    }
  }

  /// Get device from cache
  ///
  /// Returns null if device not found.
  /// Throws [Exception] if storage operation fails.
  Future<SaunaController?> getDevice(String deviceId) async {
    try {
      final box = await _getDevicesBox();
      final data = box.get(deviceId) as Map?;
      if (data == null) {
        AppLogger.cache('get', deviceId, hit: false);
        return null;
      }
      AppLogger.cache('get', deviceId, hit: true);
      return _mapToDevice(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.e('Failed to get cached device', error: e);
      rethrow;
    }
  }

  /// Get all devices from cache
  ///
  /// Returns empty list if no devices cached.
  /// Throws [Exception] if storage operation fails.
  Future<List<SaunaController>> getDevices() async {
    try {
      final box = await _getDevicesBox();
      final devices = box.values
          .map((data) => _mapToDevice(Map<String, dynamic>.from(data as Map)))
          .toList();
      AppLogger.cache('getDevices', '${devices.length} devices');
      return devices;
    } catch (e) {
      AppLogger.e('Failed to get cached devices', error: e);
      rethrow;
    }
  }

  /// Save sensor to cache
  ///
  /// Throws [Exception] if storage operation fails.
  Future<void> saveSensor(SensorDevice sensor) async {
    try {
      final box = await _getSensorsBox();
      final data = _sensorToMap(sensor);
      await box.put(sensor.deviceId, data);
      AppLogger.cache('save', sensor.deviceId);
    } catch (e) {
      AppLogger.e('Failed to cache sensor', error: e);
      rethrow;
    }
  }

  /// Get sensor from cache
  ///
  /// Returns null if sensor not found.
  /// Throws [Exception] if storage operation fails.
  Future<SensorDevice?> getSensor(String sensorId) async {
    try {
      final box = await _getSensorsBox();
      final data = box.get(sensorId) as Map?;
      if (data == null) {
        AppLogger.cache('get', sensorId, hit: false);
        return null;
      }
      AppLogger.cache('get', sensorId, hit: true);
      return _mapToSensor(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.e('Failed to get cached sensor', error: e);
      rethrow;
    }
  }

  /// Get sensors for a controller
  ///
  /// Returns all sensors linked to the specified controller.
  /// Returns empty list if no sensors found.
  Future<List<SensorDevice>> getSensorsForController(
    String controllerId,
  ) async {
    try {
      final box = await _getSensorsBox();
      final sensors = box.values
          .map((data) => _mapToSensor(Map<String, dynamic>.from(data as Map)))
          .where((sensor) => sensor.linkedControllerId == controllerId)
          .toList();
      AppLogger.cache(
        'getSensorsForController',
        '$controllerId: ${sensors.length} sensors',
      );
      return sensors;
    } catch (e) {
      AppLogger.e('Failed to get cached sensors', error: e);
      rethrow;
    }
  }

  /// Clear all cached data
  ///
  /// Throws [Exception] if storage operation fails.
  Future<void> clearAll() async {
    try {
      final devicesBox = await _getDevicesBox();
      final sensorsBox = await _getSensorsBox();
      await devicesBox.clear();
      await sensorsBox.clear();
      AppLogger.cache('clear', 'all device data');
    } catch (e) {
      AppLogger.e('Failed to clear device cache', error: e);
      rethrow;
    }
  }

  /// Convert device to map for storage
  Map<String, dynamic> _deviceToMap(SaunaController device) {
    return {
      'deviceId': device.deviceId,
      'name': device.name,
      'modelNumber': device.modelNumber,
      'serialNumber': device.serialNumber,
      'powerState': device.powerState.name,
      'heatingStatus': device.heatingStatus.name,
      'connectionStatus': device.connectionStatus.name,
      'currentTemperature': device.currentTemperature,
      'targetTemperature': device.targetTemperature,
      'minTemperature': device.minTemperature,
      'maxTemperature': device.maxTemperature,
      'currentHumidity': device.currentHumidity,
      'targetHumidity': device.targetHumidity,
      'lastUpdated': device.lastUpdated?.toIso8601String(),
      'linkedSensorIds': device.linkedSensorIds,
    };
  }

  /// Convert map to device entity
  SaunaController _mapToDevice(Map<String, dynamic> map) {
    return SaunaController(
      deviceId: map['deviceId'] as String,
      name: map['name'] as String,
      modelNumber: map['modelNumber'] as String,
      serialNumber: map['serialNumber'] as String,
      powerState: PowerState.values.firstWhere(
        (e) => e.name == map['powerState'],
        orElse: () => PowerState.unknown,
      ),
      heatingStatus: HeatingStatus.values.firstWhere(
        (e) => e.name == map['heatingStatus'],
        orElse: () => HeatingStatus.unknown,
      ),
      connectionStatus: ConnectionStatus.values.firstWhere(
        (e) => e.name == map['connectionStatus'],
        orElse: () => ConnectionStatus.unknown,
      ),
      currentTemperature: map['currentTemperature'] as double?,
      targetTemperature: map['targetTemperature'] as double?,
      minTemperature: map['minTemperature'] as double?,
      maxTemperature: map['maxTemperature'] as double?,
      currentHumidity: map['currentHumidity'] as double?,
      targetHumidity: map['targetHumidity'] as double?,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : null,
      linkedSensorIds:
          (map['linkedSensorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Convert sensor to map for storage
  Map<String, dynamic> _sensorToMap(SensorDevice sensor) {
    return {
      'deviceId': sensor.deviceId,
      'name': sensor.name,
      'type': sensor.type.name,
      'linkedControllerId': sensor.linkedControllerId,
      'temperature': sensor.temperature,
      'humidity': sensor.humidity,
      'batteryLevel': sensor.batteryLevel,
      'lastUpdated': sensor.lastUpdated?.toIso8601String(),
      'isOnline': sensor.isOnline,
    };
  }

  /// Convert map to sensor entity
  SensorDevice _mapToSensor(Map<String, dynamic> map) {
    return SensorDevice(
      deviceId: map['deviceId'] as String,
      name: map['name'] as String,
      type: SensorType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SensorType.unknown,
      ),
      linkedControllerId: map['linkedControllerId'] as String?,
      temperature: map['temperature'] as double?,
      humidity: map['humidity'] as double?,
      batteryLevel: map['batteryLevel'] as int?,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : null,
      isOnline: map['isOnline'] as bool? ?? false,
    );
  }
}
