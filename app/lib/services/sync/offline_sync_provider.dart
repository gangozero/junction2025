/// Offline sync service provider
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/control/data/datasources/control_local_datasource.dart';
import '../../features/control/presentation/providers/control_provider.dart';
import '../../features/events/data/datasources/events_local_datasource.dart';
import '../../features/events/presentation/providers/events_provider.dart';
import '../sync/offline_sync_service.dart';

/// Offline sync service provider
///
/// Provides singleton instance of offline sync service
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final controlLocalDataSource = ControlLocalDataSource()..init();
  final controlRepository = ref.read(controlRepositoryProvider);
  final eventsLocalDataSource = EventsLocalDataSource()..init();
  final eventsRepository = ref.read(eventsRepositoryProvider);

  final service = OfflineSyncService(
    controlLocalDataSource: controlLocalDataSource,
    controlRepository: controlRepository,
    eventsLocalDataSource: eventsLocalDataSource,
    eventsRepository: eventsRepository,
    connectivity: Connectivity(),
  );

  // Initialize service
  service.init();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Online status provider
///
/// Exposes current network connectivity status
final onlineStatusProvider = Provider<bool>((ref) {
  final syncService = ref.watch(offlineSyncServiceProvider);
  return syncService.isOnline;
});

/// Sync status provider
///
/// Exposes whether sync is currently in progress
final syncStatusProvider = Provider<bool>((ref) {
  final syncService = ref.watch(offlineSyncServiceProvider);
  return syncService.isSyncing;
});
