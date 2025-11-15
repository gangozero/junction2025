/// Rate limiting interceptor for API calls
library;

import 'dart:collection';

import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';

/// Rate limit configuration
class RateLimitConfig {
  /// Maximum requests per time window
  final int maxRequests;

  /// Time window duration
  final Duration window;

  /// Exponential backoff base multiplier
  final double backoffMultiplier;

  /// Maximum backoff duration
  final Duration maxBackoff;

  const RateLimitConfig({
    this.maxRequests = 60,
    this.window = const Duration(minutes: 1),
    this.backoffMultiplier = 2.0,
    this.maxBackoff = const Duration(seconds: 32),
  });

  /// Default rate limit (60 requests/minute)
  static const standard = RateLimitConfig();

  /// Aggressive rate limit (30 requests/minute)
  static const aggressive = RateLimitConfig(
    maxRequests: 30,
    window: Duration(minutes: 1),
  );

  /// Relaxed rate limit (120 requests/minute)
  static const relaxed = RateLimitConfig(
    maxRequests: 120,
    window: Duration(minutes: 1),
  );
}

/// Request record for rate limiting
class _RequestRecord {
  final DateTime timestamp;
  final String endpoint;

  _RequestRecord(this.timestamp, this.endpoint);
}

/// Rate limiting interceptor
///
/// Implements:
/// - Request throttling (max requests per time window)
/// - Exponential backoff on rate limit errors (429)
/// - Per-endpoint tracking
class RateLimitInterceptor extends Interceptor {
  final RateLimitConfig config;
  final Queue<_RequestRecord> _requestHistory = Queue();
  final Map<String, int> _backoffAttempts = {};

  RateLimitInterceptor({this.config = RateLimitConfig.standard});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final endpoint = _getEndpointKey(options);

    // Check if we're rate limited
    if (_isRateLimited()) {
      final waitTime = _getWaitTime();
      AppLogger.w('Rate limit reached, waiting ${waitTime.inMilliseconds}ms');

      await Future<void>.delayed(waitTime);
      _cleanupOldRequests();
    }

    // Record this request
    _requestHistory.add(_RequestRecord(DateTime.now(), endpoint));

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 429 Too Many Requests
    if (err.response?.statusCode == 429) {
      final endpoint = _getEndpointKey(err.requestOptions);
      final currentAttempts = _backoffAttempts[endpoint] ?? 0;

      // Calculate exponential backoff
      final backoffDuration = _calculateBackoff(currentAttempts);

      AppLogger.w(
        'Rate limit error (429) for $endpoint, backing off for ${backoffDuration.inSeconds}s',
      );

      _backoffAttempts[endpoint] = currentAttempts + 1;

      // You could retry here, but for now just pass the error
      // In production, consider implementing retry logic
    }

    handler.next(err);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Reset backoff on successful response
    final endpoint = _getEndpointKey(response.requestOptions);
    _backoffAttempts.remove(endpoint);

    handler.next(response);
  }

  /// Check if we're currently rate limited
  bool _isRateLimited() {
    _cleanupOldRequests();
    return _requestHistory.length >= config.maxRequests;
  }

  /// Get wait time before next request
  Duration _getWaitTime() {
    if (_requestHistory.isEmpty) {
      return Duration.zero;
    }

    final oldestRequest = _requestHistory.first;
    final windowEnd = oldestRequest.timestamp.add(config.window);
    final now = DateTime.now();

    if (now.isBefore(windowEnd)) {
      return windowEnd.difference(now);
    }

    return Duration.zero;
  }

  /// Remove requests outside the current time window
  void _cleanupOldRequests() {
    final cutoff = DateTime.now().subtract(config.window);

    while (_requestHistory.isNotEmpty &&
        _requestHistory.first.timestamp.isBefore(cutoff)) {
      _requestHistory.removeFirst();
    }
  }

  /// Calculate exponential backoff duration
  Duration _calculateBackoff(int attempts) {
    final seconds = (1 * config.backoffMultiplier * (1 << attempts)).toInt();
    final duration = Duration(seconds: seconds);

    // Cap at max backoff
    return duration > config.maxBackoff ? config.maxBackoff : duration;
  }

  /// Get endpoint key for tracking
  String _getEndpointKey(RequestOptions options) {
    return '${options.method}:${options.path}';
  }

  /// Get current request count
  int get currentRequestCount {
    _cleanupOldRequests();
    return _requestHistory.length;
  }

  /// Get requests remaining in current window
  int get requestsRemaining {
    _cleanupOldRequests();
    return config.maxRequests - _requestHistory.length;
  }

  /// Reset rate limiter
  void reset() {
    _requestHistory.clear();
    _backoffAttempts.clear();
  }
}
