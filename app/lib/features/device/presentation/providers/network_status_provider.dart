/// Network status provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/network/network_info.dart';

/// Network status provider
///
/// Monitors network connectivity and provides real-time status updates
final networkStatusProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});

/// Network info provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});
