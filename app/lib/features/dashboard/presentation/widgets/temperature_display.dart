/// Temperature display widget
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../device/domain/entities/sauna_controller.dart';

/// Temperature display widget
///
/// Shows current and target temperature with progress indicator
class TemperatureDisplay extends StatelessWidget {
  final SaunaController device;

  const TemperatureDisplay({required this.device, super.key});

  @override
  Widget build(BuildContext context) {
    final currentTemp = device.currentTemperature;
    final targetTemp = device.targetTemperature;
    final progress = device.temperatureProgress;

    if (currentTemp == null) {
      return const Text(
        'No temperature data',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current and target temperature
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Current temperature (large)
            Text(
              '${currentTemp.toStringAsFixed(1)}${AppStrings.celsius}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTemperatureColor(currentTemp),
              ),
            ),
            if (targetTemp != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                size: LayoutConstants.iconSizeSmall,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              // Target temperature (smaller)
              Text(
                '${targetTemp.toStringAsFixed(0)}${AppStrings.celsius}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
        const SizedBox(height: LayoutConstants.spacingSmall),

        // Progress bar (if target is set)
        if (progress != null && targetTemp != null) ...[
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% to target',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],

        // Humidity display (if available)
        if (device.hasHumidity) ...[
          const SizedBox(height: LayoutConstants.spacingSmall),
          Row(
            children: [
              const Icon(
                Icons.water_drop,
                size: LayoutConstants.iconSizeSmall,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                '${device.currentHumidity!.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (device.hasTargetHumidity) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: LayoutConstants.iconSizeSmall - 4,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '${device.targetHumidity!.toStringAsFixed(0)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Get color based on temperature
  Color _getTemperatureColor(double temp) {
    if (temp < 40) return Colors.blue;
    if (temp < 60) return Colors.orange;
    if (temp < 80) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get color based on progress
  Color _getProgressColor(double progress) {
    if (progress < 0.33) return Colors.blue;
    if (progress < 0.66) return Colors.orange;
    if (progress < 0.9) return Colors.deepOrange;
    return Colors.green;
  }
}
