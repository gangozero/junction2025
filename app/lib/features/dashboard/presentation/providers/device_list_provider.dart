/// Device list state provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../device/data/datasources/device_local_datasource.dart';
import '../../../device/data/datasources/device_remote_datasource.dart';
import '../../../device/data/repositories/device_repository_impl.dart';
import '../../../device/domain/entities/sauna_controller.dart';
import '../../../device/domain/repositories/device_repository.dart';

/// Device repository provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    remoteDataSource: DeviceRemoteDataSource.create(),
    localDataSource: DeviceLocalDataSource(),
  );
});

/// Device list provider
///
/// Provides list of all devices for the current user
final deviceListProvider = FutureProvider<List<SaunaController>>((ref) async {
  final repository = ref.read(deviceRepositoryProvider);

  final result = await repository.getDevices();

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (devices) => devices,
  );
});

/// Specific device provider
///
/// Provides details for a single device by ID
final deviceProvider = FutureProvider.family<SaunaController, String>((
  ref,
  deviceId,
) async {
  final repository = ref.read(deviceRepositoryProvider);

  final result = await repository.getDeviceState(deviceId);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (device) => device,
  );
});

/// Cached devices provider (offline-first)
///
/// Returns immediately from cache without network call
final cachedDevicesProvider = FutureProvider<List<SaunaController>>((
  ref,
) async {
  final repository = ref.read(deviceRepositoryProvider);

  final result = await repository.getCachedDevices();

  return result.fold((failure) => [], (devices) => devices);
});
