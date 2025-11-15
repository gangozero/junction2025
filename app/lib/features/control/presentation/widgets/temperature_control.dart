/// Temperature control widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/validate_temperature_usecase.dart';
import '../../../device/domain/entities/sauna_controller.dart';
import '../providers/control_provider.dart';

/// Temperature control slider widget
///
/// Displays a slider that allows users to adjust target temperature
/// Shows loading state during command execution
/// Prevents commands when device is offline or powered off
class TemperatureControl extends ConsumerStatefulWidget {
  final SaunaController device;

  const TemperatureControl({required this.device, super.key});

  @override
  ConsumerState<TemperatureControl> createState() => _TemperatureControlState();
}

class _TemperatureControlState extends ConsumerState<TemperatureControl> {
  late double _sliderValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.device.targetTemperature ?? 80.0;
  }

  @override
  void didUpdateWidget(TemperatureControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging &&
        widget.device.targetTemperature != null &&
        widget.device.targetTemperature != _sliderValue) {
      _sliderValue = widget.device.targetTemperature!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlState = ref.watch(
      temperatureControlProvider(widget.device.deviceId),
    );
    final isOffline =
        widget.device.connectionStatus == ConnectionStatus.offline;
    final isPoweredOff = widget.device.powerState == PowerState.off;
    final isDisabled = isOffline || isPoweredOff;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target Temperature',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            controlState.when(
              data: (temperature) => Text(
                '${_sliderValue.toInt()}°C',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDisabled ? Colors.grey : Colors.blue,
                ),
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (error, stack) => Text(
                '${_sliderValue.toInt()}°C',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _sliderValue,
          min: 40,
          max: 110,
          divisions: 70,
          label: '${_sliderValue.toInt()}°C',
          onChanged: isDisabled
              ? null
              : (value) {
                  setState(() {
                    _sliderValue = value;
                    _isDragging = true;
                  });
                },
          onChangeEnd: (value) {
            _isDragging = false;
            _handleTemperatureChange(value);
          },
        ),
        const SizedBox(height: 8),
        // Estimated time to reach target (T072)
        if (!isDisabled &&
            widget.device.currentTemperature != null &&
            widget.device.targetTemperature != null)
          _buildEstimatedTime(),
        const SizedBox(height: 8),
        // Temperature presets (T074)
        if (!isDisabled) _buildTemperaturePresets(),
        if (isPoweredOff)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Turn on sauna to adjust temperature',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          ),
        if (isOffline)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Device is offline',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  /// Build estimated time to reach target temperature (T072)
  Widget _buildEstimatedTime() {
    final current = widget.device.currentTemperature!;
    final target = widget.device.targetTemperature!;
    final difference = (target - current).abs();

    // Don't show if already at target
    if (difference < 1.0) {
      return const SizedBox.shrink();
    }

    // Estimate heating/cooling rate
    // Typical sauna heater: ~1°C per minute when heating
    // Cooling is slower: ~0.5°C per minute
    final isHeating = target > current;
    final ratePerMinute = isHeating ? 1.0 : 0.5;
    final estimatedMinutes = (difference / ratePerMinute).ceil();

    // Format time display
    String timeText;
    if (estimatedMinutes < 60) {
      timeText = '$estimatedMinutes min';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      timeText = '${hours}h ${minutes}m';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            isHeating ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            'Est. time to ${target.toInt()}°C: $timeText',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Show warning dialog for high temperature (T071)
  Future<bool> _showHighTemperatureWarning(
    double targetTemp,
    double threshold,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('High Temperature Warning'),
          ],
        ),
        content: Text(
          'You are setting the temperature to ${targetTemp.toInt()}°C, '
          'which is above the recommended ${threshold.toInt()}°C for this model.\n\n'
          'High temperatures can increase wear on components and may be uncomfortable. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Build temperature preset buttons (T074)
  Widget _buildTemperaturePresets() {
    const presets = [60.0, 70.0, 80.0, 90.0];

    return Wrap(
      spacing: 8,
      children: presets.map((temp) {
        final isSelected = (_sliderValue - temp).abs() < 2.0;
        return FilterChip(
          label: Text('${temp.toInt()}°C'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _sliderValue = temp;
              });
              _handleTemperatureChange(temp);
            }
          },
        );
      }).toList(),
    );
  }

  Future<void> _handleTemperatureChange(double targetTemperature) async {
    // Model-specific temperature validation (T069, T071)
    final tempValidateUseCase = const ValidateTemperatureUseCase();
    final tempValidationResult = tempValidateUseCase(
      device: widget.device,
      targetTemperature: targetTemperature,
    );

    // Check if validation failed
    final validationFailed = tempValidationResult.fold((failure) {
      // Show validation error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset slider to previous value
        setState(() {
          _sliderValue = widget.device.targetTemperature ?? 80.0;
        });
      }
      return true;
    }, (_) => false);

    if (validationFailed) return;

    // Show warning dialog for high temperatures (T071)
    final warningThreshold = tempValidateUseCase.getWarningThreshold(
      widget.device.modelNumber,
    );
    if (targetTemperature > warningThreshold) {
      final confirmed = await _showHighTemperatureWarning(
        targetTemperature,
        warningThreshold,
      );
      if (!confirmed) {
        // User cancelled, reset slider
        if (mounted) {
          setState(() {
            _sliderValue = widget.device.targetTemperature ?? 80.0;
          });
        }
        return;
      }
    }

    // Additional general command validation
    final validateUseCase = ref.read(validateCommandUseCaseProvider);
    final validationResult = await validateUseCase.validateTemperatureCommand(
      device: widget.device,
      targetTemperature: targetTemperature,
    );

    validationResult.fold(
      (failure) {
        // Show validation error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.userMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          // Reset slider to previous value
          setState(() {
            _sliderValue = widget.device.targetTemperature ?? 80.0;
          });
        }
      },
      (_) async {
        // Validation passed, execute command
        final notifier = ref.read(
          temperatureControlProvider(widget.device.deviceId).notifier,
        );

        try {
          await notifier.setTemperature(targetTemperature);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Temperature set to ${targetTemperature.toInt()}°C',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (error) {
          // Error already handled by notifier, show user feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Command failed: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            // Reset slider to previous value
            setState(() {
              _sliderValue = widget.device.targetTemperature ?? 80.0;
            });
          }
        }
      },
    );
  }
}
