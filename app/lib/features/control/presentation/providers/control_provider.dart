/// Control state provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/control_local_datasource.dart';
import '../../data/datasources/control_remote_datasource.dart';
import '../../data/repositories/control_repository_impl.dart';
import '../../domain/repositories/control_repository.dart';
import '../../domain/usecases/validate_command_usecase.dart';

/// Control local data source provider
final controlLocalDataSourceProvider = Provider<ControlLocalDataSource>((ref) {
  final dataSource = ControlLocalDataSource();
  // Initialize Hive box
  dataSource.init();
  return dataSource;
});

/// Control remote data source provider
final controlRemoteDataSourceProvider = Provider<ControlRemoteDataSource>((
  ref,
) {
  return ControlRemoteDataSource.create();
});

/// Control repository provider
final controlRepositoryProvider = Provider<ControlRepository>((ref) {
  return ControlRepositoryImpl(
    remoteDataSource: ref.watch(controlRemoteDataSourceProvider),
    localDataSource: ref.watch(controlLocalDataSourceProvider),
  );
});

/// Power control state notifier
///
/// Manages power on/off commands for a device
class PowerControlNotifier extends StateNotifier<AsyncValue<bool>> {
  PowerControlNotifier(this.deviceId, this.repository)
    : super(const AsyncValue.loading()) {
    _init();
  }

  final String deviceId;
  final ControlRepository repository;

  void _init() {
    // Initialize with no specific state
    state = const AsyncValue.data(false);
  }

  /// Send power ON command
  Future<void> powerOn() async {
    state = const AsyncValue.loading();

    final result = await repository.sendPowerCommand(
      deviceId: deviceId,
      powerOn: true,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.userMessage, StackTrace.current);
      },
      (command) {
        state = const AsyncValue.data(true);
      },
    );
  }

  /// Send power OFF command
  Future<void> powerOff() async {
    state = const AsyncValue.loading();

    final result = await repository.sendPowerCommand(
      deviceId: deviceId,
      powerOn: false,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.userMessage, StackTrace.current);
      },
      (command) {
        state = const AsyncValue.data(false);
      },
    );
  }

  /// Toggle power state
  Future<void> toggle(bool currentState) async {
    if (currentState) {
      await powerOff();
    } else {
      await powerOn();
    }
  }
}

/// Power control state provider (family - per device)
final powerControlProvider =
    StateNotifierProvider.family<
      PowerControlNotifier,
      AsyncValue<bool>,
      String
    >((ref, deviceId) {
      final repository = ref.watch(controlRepositoryProvider);
      return PowerControlNotifier(deviceId, repository);
    });

/// Temperature control state notifier
///
/// Manages temperature adjustment commands for a device
class TemperatureControlNotifier extends StateNotifier<AsyncValue<double?>> {
  TemperatureControlNotifier(this.deviceId, this.repository)
    : super(const AsyncValue.data(null));

  final String deviceId;
  final ControlRepository repository;

  /// Set target temperature
  Future<void> setTemperature(double targetTemperature) async {
    state = const AsyncValue.loading();

    final result = await repository.sendTemperatureCommand(
      deviceId: deviceId,
      targetTemperature: targetTemperature,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.userMessage, StackTrace.current);
      },
      (command) {
        state = AsyncValue.data(targetTemperature);
      },
    );
  }
}

/// Temperature control state provider (family - per device)
final temperatureControlProvider =
    StateNotifierProvider.family<
      TemperatureControlNotifier,
      AsyncValue<double?>,
      String
    >((ref, deviceId) {
      final repository = ref.watch(controlRepositoryProvider);
      return TemperatureControlNotifier(deviceId, repository);
    });

/// Validate command use case provider
final validateCommandUseCaseProvider = Provider<ValidateCommandUseCase>((ref) {
  final repository = ref.watch(controlRepositoryProvider);
  return ValidateCommandUseCase(repository: repository);
});
