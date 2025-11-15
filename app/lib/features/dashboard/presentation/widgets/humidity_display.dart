/// Humidity display widget
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../device/domain/entities/sensor_device.dart';

/// Humidity display widget
///
/// Shows humidity percentage from sensor (conditional - only if sensor has humidity)
class HumidityDisplay extends StatelessWidget {
  final SensorDevice sensor;

  const HumidityDisplay({required this.sensor, super.key});

  @override
  Widget build(BuildContext context) {
    final humidity = sensor.humidity;

    if (humidity == null || !sensor.type.hasHumidity) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(LayoutConstants.spacingSmall),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop,
            size: LayoutConstants.iconSizeMedium,
            color: Colors.blue,
          ),
          const SizedBox(width: LayoutConstants.spacingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Humidity',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                '${humidity.toStringAsFixed(1)}${AppStrings.percentSymbol}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
