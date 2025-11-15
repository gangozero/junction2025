/// Power control widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../device/domain/entities/sauna_controller.dart';
import '../providers/control_provider.dart';

/// Power control button widget
///
/// Displays a power button that allows users to turn sauna on/off
/// Shows loading state during command execution
/// Prevents commands when device is offline
class PowerControl extends ConsumerWidget {
  final SaunaController device;

  const PowerControl({required this.device, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(powerControlProvider(device.deviceId));
    final isOffline = device.connectionStatus == ConnectionStatus.offline;

    // Get current power state from device
    final isPoweredOn = device.powerState == PowerState.on;

    return controlState.when(
      data: (commandResult) => _buildPowerButton(
        context: context,
        ref: ref,
        isPoweredOn: isPoweredOn,
        isOffline: isOffline,
      ),
      loading: () => const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stackTrace) => _buildPowerButton(
        context: context,
        ref: ref,
        isPoweredOn: isPoweredOn,
        isOffline: isOffline,
        hasError: true,
      ),
    );
  }

  Widget _buildPowerButton({
    required BuildContext context,
    required WidgetRef ref,
    required bool isPoweredOn,
    required bool isOffline,
    bool hasError = false,
  }) {
    return IconButton(
      icon: Icon(
        Icons.power_settings_new,
        color: _getPowerIconColor(isPoweredOn, isOffline, hasError),
      ),
      onPressed: isOffline
          ? null
          : () => _handlePowerToggle(context, ref, isPoweredOn),
      tooltip: _getPowerTooltip(isPoweredOn, isOffline),
    );
  }

  Color _getPowerIconColor(bool isPoweredOn, bool isOffline, bool hasError) {
    if (isOffline) return Colors.grey.shade400;
    if (hasError) return Colors.red;
    return isPoweredOn ? Colors.green : Colors.grey.shade600;
  }

  String _getPowerTooltip(bool isPoweredOn, bool isOffline) {
    if (isOffline) return 'Device is offline';
    return isPoweredOn ? 'Turn off' : 'Turn on';
  }

  Future<void> _handlePowerToggle(
    BuildContext context,
    WidgetRef ref,
    bool currentlyPoweredOn,
  ) async {
    // Validate command before sending
    final validateUseCase = ref.read(validateCommandUseCaseProvider);
    final validationResult = await validateUseCase.validatePowerCommand(
      device: device,
      powerOn: !currentlyPoweredOn,
    );

    validationResult.fold(
      (failure) {
        // Show validation error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.userMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      (_) async {
        // Validation passed, execute command
        final notifier = ref.read(
          powerControlProvider(device.deviceId).notifier,
        );

        try {
          if (currentlyPoweredOn) {
            await notifier.powerOff();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Power turned off successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            await notifier.powerOn();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Power turned on successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (error) {
          // Error already handled by notifier, show user feedback
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Command failed: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }
}
