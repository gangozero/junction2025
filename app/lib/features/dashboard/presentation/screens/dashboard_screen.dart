/// Dashboard screen with responsive layout
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../providers/device_list_provider.dart';
import '../widgets/device_status_card.dart';

/// Dashboard screen
///
/// Displays all user's devices with responsive layout:
/// - Mobile: Single column list
/// - Tablet: 2-column grid
/// - Desktop: 3-column grid
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceListAsync = ref.watch(deviceListProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine grid columns based on screen size
    final crossAxisCount = screenWidth >= LayoutConstants.desktopBreakpoint
        ? LayoutConstants.gridColumnsDesktop
        : screenWidth >= LayoutConstants.tabletBreakpoint
        ? LayoutConstants.gridColumnsTablet
        : LayoutConstants.gridColumnsMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deviceListProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: deviceListAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No devices found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add a sauna controller to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(deviceListProvider);
              await ref.read(deviceListProvider.future);
            },
            child: Padding(
              padding: EdgeInsets.all(
                screenWidth < LayoutConstants.tabletBreakpoint
                    ? LayoutConstants.paddingMobile
                    : LayoutConstants.paddingDesktop,
              ),
              child: crossAxisCount == 1
                  ? ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: LayoutConstants.spacingMedium,
                          ),
                          child: DeviceStatusCard(device: devices[index]),
                        );
                      },
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: LayoutConstants.spacingMedium,
                        mainAxisSpacing: LayoutConstants.spacingMedium,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return DeviceStatusCard(device: devices[index]);
                      },
                    ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading devices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(deviceListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
