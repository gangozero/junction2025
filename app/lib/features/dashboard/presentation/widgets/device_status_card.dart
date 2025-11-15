/// Device status card widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../device/domain/entities/sauna_controller.dart';
import '../providers/device_list_provider.dart';
import 'heating_status.dart';
import 'temperature_display.dart';

/// Device status card
///
/// Displays sauna controller status with real-time updates
class DeviceStatusCard extends ConsumerWidget {
  final String deviceId;

  const DeviceStatusCard({required this.deviceId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to real-time updates
    final deviceStateAsync = ref.watch(deviceStateProvider(deviceId));

    return deviceStateAsync.when(
      data: (device) {
        // Different card designs based on device type
        if (device.deviceType == DeviceType.saunaSensor) {
          return _SensorCard(device: device);
        } else {
          return _ControllerCard(device: device);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

/// Controller card for Fenix devices
class _ControllerCard extends StatelessWidget {
  final SaunaController device;

  const _ControllerCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: LayoutConstants.cardElevation,
      color: Colors.deepOrange.shade50,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to device details screen
        },
        borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(LayoutConstants.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with controller icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings_remote,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name.isNotEmpty
                                    ? device.name
                                    : device.serialNumber,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Controller',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ConnectionStatusIndicator(status: device.connectionStatus),
                ],
              ),
              const SizedBox(height: LayoutConstants.spacingMedium),

              // Temperature display
              if (device.hasTemperature)
                TemperatureDisplay(device: device)
              else
                _NoTemperatureDisplay(
                  heatingStatus: device.heatingStatus,
                  connectionStatus: device.connectionStatus,
                  powerState: device.powerState,
                ),
              const SizedBox(height: LayoutConstants.spacingMedium),

              // Heating status and power state
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeatingStatusWidget(status: device.heatingStatus),
                  _PowerStateIndicator(state: device.powerState),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sensor card for SaunaSensor devices
class _SensorCard extends StatelessWidget {
  final SaunaController device;

  const _SensorCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: LayoutConstants.cardElevation,
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to device details screen
        },
        borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(LayoutConstants.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sensor icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sensors,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.serialNumber,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Sensor',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ConnectionStatusIndicator(status: device.connectionStatus),
                ],
              ),
              const SizedBox(height: LayoutConstants.spacingMedium),

              // Sensor readings in a compact row
              if (device.hasTemperature || device.hasHumidity)
                Row(
                  children: [
                    if (device.hasTemperature) ...[
                      Expanded(
                        child: _SensorReading(
                          icon: Icons.thermostat,
                          label: 'Temperature',
                          value:
                              '${device.currentTemperature!.toStringAsFixed(1)}°C',
                          color: _getTemperatureColor(
                            device.currentTemperature!,
                          ),
                        ),
                      ),
                    ],
                    if (device.hasTemperature && device.hasHumidity)
                      const SizedBox(width: 12),
                    if (device.hasHumidity) ...[
                      Expanded(
                        child: _SensorReading(
                          icon: Icons.water_drop,
                          label: 'Humidity',
                          value:
                              '${device.currentHumidity!.toStringAsFixed(1)}%',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                )
              else
                _NoTemperatureDisplay(
                  heatingStatus: device.heatingStatus,
                  connectionStatus: device.connectionStatus,
                  powerState: device.powerState,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 40) return Colors.blue;
    if (temp < 60) return Colors.orange;
    if (temp < 80) return Colors.deepOrange;
    return Colors.red;
  }
}

/// Sensor reading widget
class _SensorReading extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SensorReading({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection status indicator
class _ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      ConnectionStatus.online => (Icons.cloud_done, Colors.green, 'Online'),
      ConnectionStatus.offline => (Icons.cloud_off, Colors.red, 'Offline'),
      ConnectionStatus.connecting => (
        Icons.cloud_sync,
        Colors.orange,
        'Connecting',
      ),
      ConnectionStatus.unknown => (Icons.help_outline, Colors.grey, 'Unknown'),
    };

    return Tooltip(
      message: label,
      child: Icon(icon, color: color, size: LayoutConstants.iconSizeMedium),
    );
  }
}

/// No temperature display - shows context-aware message
class _NoTemperatureDisplay extends StatelessWidget {
  final HeatingStatus heatingStatus;
  final ConnectionStatus connectionStatus;
  final PowerState powerState;

  const _NoTemperatureDisplay({
    required this.heatingStatus,
    required this.connectionStatus,
    required this.powerState,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    // Determine message based on device state
    if (connectionStatus == ConnectionStatus.offline) {
      message = 'Device offline';
      icon = Icons.cloud_off;
      color = Colors.red;
    } else if (powerState == PowerState.off) {
      message = 'Device off';
      icon = Icons.power_settings_new;
      color = Colors.grey;
    } else if (heatingStatus == HeatingStatus.idle) {
      message = 'Standby mode';
      icon = Icons.bedtime;
      color = Colors.orange;
    } else if (heatingStatus == HeatingStatus.cooling) {
      message = 'Cooling down';
      icon = Icons.ac_unit;
      color = Colors.blue;
    } else {
      message = 'No temperature data';
      icon = Icons.thermostat;
      color = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          message,
          style: TextStyle(color: color, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

/// Power state indicator
class _PowerStateIndicator extends StatelessWidget {
  final PowerState state;

  const _PowerStateIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final isOn = state.isOn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOn
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOn ? Colors.green : Colors.grey, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.power_settings_new,
            size: LayoutConstants.iconSizeSmall,
            color: isOn ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isOn ? 'ON' : 'OFF',
            style: TextStyle(
              color: isOn ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
