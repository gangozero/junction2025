/// Connection status banner widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../device/presentation/providers/network_status_provider.dart';

/// Connection status banner
///
/// Displays a banner at the top of the screen when offline
class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatusAsync = ref.watch(networkStatusProvider);

    // Only show banner if explicitly offline
    return networkStatusAsync.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }

        return _buildOfflineBanner(ref);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildOfflineBanner(ref),
    );
  }

  Widget _buildOfflineBanner(WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: LayoutConstants.spacingMedium,
        vertical: LayoutConstants.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: LayoutConstants.iconSizeSmall,
          ),
          const SizedBox(width: LayoutConstants.spacingSmall),
          const Expanded(
            child: Text(
              'No internet connection. Showing cached data.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            iconSize: LayoutConstants.iconSizeSmall,
            onPressed: () {
              ref.invalidate(networkStatusProvider);
            },
            tooltip: 'Retry connection',
          ),
        ],
      ),
    );
  }
}
