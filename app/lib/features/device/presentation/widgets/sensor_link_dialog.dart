/// Sensor link dialog widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/device_list_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../domain/entities/sensor_device.dart';
import '../../domain/usecases/associate_sensors_usecase.dart';

/// Sensor link dialog
///
/// Allows manual linking of sensors to a controller
class SensorLinkDialog extends ConsumerStatefulWidget {
  final String controllerId;
  final List<SensorDevice> availableSensors;

  const SensorLinkDialog({
    required this.controllerId,
    required this.availableSensors,
    super.key,
  });

  @override
  ConsumerState<SensorLinkDialog> createState() => _SensorLinkDialogState();
}

class _SensorLinkDialogState extends ConsumerState<SensorLinkDialog> {
  SensorDevice? _selectedSensor;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link Sensor'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a sensor to link to this controller:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: LayoutConstants.spacingMedium),

            // Sensor list
            if (widget.availableSensors.isEmpty)
              const Padding(
                padding: EdgeInsets.all(LayoutConstants.spacingMedium),
                child: Center(
                  child: Text(
                    'No available sensors found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableSensors.length,
                  itemBuilder: (context, index) {
                    final sensor = widget.availableSensors[index];
                    final isSelected =
                        _selectedSensor?.deviceId == sensor.deviceId;

                    return ListTile(
                      selected: isSelected,
                      leading: Icon(
                        _getSensorIcon(sensor.type),
                        color: sensor.isOnline ? Colors.green : Colors.grey,
                      ),
                      title: Text(sensor.name),
                      subtitle: Text(
                        _getSensorSubtitle(sensor),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: sensor.isBatteryLow
                          ? const Icon(
                              Icons.battery_alert,
                              color: Colors.orange,
                              size: LayoutConstants.iconSizeSmall,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSensor = sensor;
                          _errorMessage = null;
                        });
                      },
                    );
                  },
                ),
              ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: LayoutConstants.spacingMedium),
              Container(
                padding: const EdgeInsets.all(LayoutConstants.spacingSmall),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isLoading || _selectedSensor == null ? null : _handleLink,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Link'),
        ),
      ],
    );
  }

  Future<void> _handleLink() async {
    if (_selectedSensor == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final useCase = AssociateSensorsUseCase(
      repository: ref.read(deviceRepositoryProvider),
    );

    final result = await useCase.linkSensor(
      sensorId: _selectedSensor!.deviceId,
      controllerId: widget.controllerId,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.userMessage;
        });
      },
      (_) {
        // Success - refresh device list and close dialog
        ref.invalidate(deviceListProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sensor "${_selectedSensor!.name}" linked successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  IconData _getSensorIcon(SensorType type) {
    return switch (type) {
      SensorType.temperature => Icons.thermostat,
      SensorType.humidity => Icons.water_drop,
      SensorType.temperatureHumidity => Icons.sensors,
      SensorType.unknown => Icons.device_unknown,
    };
  }

  String _getSensorSubtitle(SensorDevice sensor) {
    final parts = <String>[];

    if (sensor.temperature != null) {
      parts.add(
        '${sensor.temperature!.toStringAsFixed(1)}${AppStrings.celsius}',
      );
    }

    if (sensor.humidity != null) {
      parts.add(
        '${sensor.humidity!.toStringAsFixed(0)}${AppStrings.percentSymbol}',
      );
    }

    if (sensor.batteryLevel != null) {
      parts.add('Battery: ${sensor.batteryLevel}%');
    }

    if (!sensor.isOnline) {
      parts.add('Offline');
    }

    return parts.join(' • ');
  }
}
