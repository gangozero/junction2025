/// WebSocket reconnection manager
library;

import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/logger.dart';

/// WebSocket reconnection manager
///
/// Manages WebSocket subscriptions with exponential backoff reconnection
class WebSocketReconnectionManager {
  final String subscription;
  final Map<String, dynamic>? variables;
  final Future<Stream<QueryResult>> Function() _subscribeFunction;

  StreamController<QueryResult>? _controller;
  StreamSubscription<QueryResult>? _subscription;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  WebSocketReconnectionManager({
    required this.subscription,
    required this.variables,
    required Future<Stream<QueryResult>> Function() subscribeFunction,
  }) : _subscribeFunction = subscribeFunction;

  /// Get the managed subscription stream
  Stream<QueryResult> get stream {
    _controller ??= StreamController<QueryResult>.broadcast(
      onListen: _connect,
      onCancel: () {
        _subscription?.cancel();
        _reconnectTimer?.cancel();
      },
    );

    return _controller!.stream;
  }

  /// Connect to WebSocket subscription
  Future<void> _connect() async {
    if (_isDisposed) return;

    try {
      AppLogger.i('Connecting WebSocket subscription');

      final subscriptionStream = await _subscribeFunction();

      _subscription = subscriptionStream.listen(
        (result) {
          if (_isDisposed) return;

          // Reset reconnect attempts on successful data
          if (!result.hasException && result.data != null) {
            _reconnectAttempts = 0;
          }

          _controller?.add(result);

          // Handle exceptions but don't close stream
          if (result.hasException) {
            AppLogger.w(
              'WebSocket subscription error',
              error: result.exception,
            );
            _scheduleReconnect();
          }
        },
        onError: (Object error) {
          if (_isDisposed) return;

          AppLogger.e('WebSocket subscription error', error: error);
          _scheduleReconnect();
        },
        onDone: () {
          if (_isDisposed) return;

          AppLogger.w('WebSocket subscription closed');
          _scheduleReconnect();
        },
      );

      AppLogger.i('WebSocket subscription connected');
    } catch (e) {
      if (_isDisposed) return;

      AppLogger.e('Failed to connect WebSocket subscription', error: e);
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_isDisposed) return;

    // Cancel existing subscription
    _subscription?.cancel();
    _subscription = null;

    // Cancel existing timer
    _reconnectTimer?.cancel();

    // Calculate backoff delay: min(2^attempts * 1s, 30s)
    final delaySeconds = _calculateBackoffDelay();

    AppLogger.i(
      'Scheduling WebSocket reconnect in ${delaySeconds}s '
      '(attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectAttempts++;
      _connect();
    });
  }

  /// Calculate exponential backoff delay
  ///
  /// Returns delay in seconds using formula: min(2^attempts, 30)
  /// - Attempt 0: 1s
  /// - Attempt 1: 2s
  /// - Attempt 2: 4s
  /// - Attempt 3: 8s
  /// - Attempt 4: 16s
  /// - Attempt 5+: 30s (max)
  int _calculateBackoffDelay() {
    final maxDelay = ApiConstants.wsMaxReconnectDelay;
    final baseDelay =
        ApiConstants.wsReconnectDelay ~/ 1000; // Convert ms to seconds

    if (_reconnectAttempts == 0) return baseDelay;

    // Exponential backoff: 2^attempts * baseDelay
    final delay = baseDelay * (1 << _reconnectAttempts); // Left shift = 2^n

    return delay > maxDelay ? maxDelay : delay;
  }

  /// Dispose the manager and clean up resources
  void dispose() {
    if (_isDisposed) return;

    AppLogger.d('Disposing WebSocket reconnection manager');

    _isDisposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _controller?.close();

    _reconnectTimer = null;
    _subscription = null;
    _controller = null;
  }

  /// Force reconnection (useful for manual retry)
  void reconnect() {
    if (_isDisposed) return;

    AppLogger.i('Forcing WebSocket reconnection');
    _reconnectAttempts = 0;
    _scheduleReconnect();
  }
}
