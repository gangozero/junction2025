/// Network information service
library;

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network information
///
/// Provides network connectivity status
class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Check if device is connected to internet
  ///
  /// Returns true if connected via WiFi, mobile, or ethernet
  Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnectedResult(result);
    } catch (e) {
      // If connectivity check fails, assume offline
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isConnectedResult);
  }

  /// Check if connectivity result indicates connection
  bool _isConnectedResult(List<ConnectivityResult> results) {
    // If any result indicates connection, device is online
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }
}
