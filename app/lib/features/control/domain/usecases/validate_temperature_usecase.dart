/// Temperature validation use case with model-specific ranges
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../device/domain/entities/sauna_controller.dart';

/// Temperature validation use case
///
/// Validates temperature commands with model-specific safe ranges
class ValidateTemperatureUseCase {
  const ValidateTemperatureUseCase();

  /// Validate temperature value against model-specific ranges
  ///
  /// Returns Either<Failure, void> - Left if validation fails, Right if valid
  Either<Failure, void> call({
    required SaunaController device,
    required double targetTemperature,
  }) {
    // Get model-specific temperature range
    final range = _getTemperatureRange(device.modelNumber);

    // Validate temperature is within safe range
    if (targetTemperature < range.min || targetTemperature > range.max) {
      final modelName = device.modelNumber.isEmpty
          ? 'this model'
          : device.modelNumber;
      return Left(
        ValidationFailure(
          'Temperature must be between ${range.min.toInt()}°C and ${range.max.toInt()}°C '
          'for $modelName',
        ),
      );
    }

    // Check if device supports fine-grained temperature control
    if (!_supportsFineTuning(device.modelNumber) &&
        targetTemperature % 5 != 0) {
      final modelName = device.modelNumber.isEmpty
          ? 'This model'
          : device.modelNumber;
      return Left(
        ValidationFailure(
          '$modelName only supports temperature '
          'adjustment in 5°C increments (e.g., 70°C, 75°C, 80°C)',
        ),
      );
    }

    // Validate temperature makes sense (not too close to current)
    if (device.targetTemperature != null) {
      final difference = (targetTemperature - device.targetTemperature!).abs();
      if (difference < 1.0) {
        return const Left(
          ValidationFailure('Temperature is already set to this value'),
        );
      }
    }

    // Warn if temperature is extremely high
    if (targetTemperature > range.warningThreshold) {
      // This is a warning, not an error - allow but notify
      return Right(null);
    }

    return const Right(null);
  }

  /// Get recommended temperature warning threshold
  double getWarningThreshold(String modelNumber) {
    return _getTemperatureRange(modelNumber).warningThreshold;
  }

  /// Get temperature range for model
  _TemperatureRange _getTemperatureRange(String modelNumber) {
    // Default ranges for unknown models
    const defaultRange = _TemperatureRange(
      min: 40.0,
      max: 110.0,
      warningThreshold: 95.0,
    );

    if (modelNumber.isEmpty) return defaultRange;

    // Model-specific temperature ranges
    // Source: Harvia product specifications
    return switch (modelNumber.toLowerCase()) {
      // Harvia Xenio series - high-end digital control
      'harvia xenio' || 'xenio' => const _TemperatureRange(
        min: 40.0,
        max: 110.0,
        warningThreshold: 100.0,
      ),

      // Harvia Cilindro series - traditional heaters
      'harvia cilindro' || 'cilindro' => const _TemperatureRange(
        min: 50.0,
        max: 100.0,
        warningThreshold: 90.0,
      ),

      // Harvia Virta series - compact heaters
      'harvia virta' || 'virta' => const _TemperatureRange(
        min: 40.0,
        max: 90.0,
        warningThreshold: 85.0,
      ),

      // Harvia Legend series - wood-burning style electric
      'harvia legend' || 'legend' => const _TemperatureRange(
        min: 50.0,
        max: 105.0,
        warningThreshold: 95.0,
      ),

      // Harvia Vega series - basic models
      'harvia vega' || 'vega' => const _TemperatureRange(
        min: 50.0,
        max: 90.0,
        warningThreshold: 85.0,
      ),

      // Default for other Harvia models
      _ when modelNumber.toLowerCase().contains('harvia') =>
        const _TemperatureRange(min: 40.0, max: 100.0, warningThreshold: 90.0),

      // Unknown models - use conservative defaults
      _ => defaultRange,
    };
  }

  /// Check if model supports fine-grained temperature control
  bool _supportsFineTuning(String modelNumber) {
    if (modelNumber.isEmpty) return true;

    // Digital models support 1°C increments
    final digitalModels = ['xenio', 'legend'];

    return digitalModels.any(
      (model) => modelNumber.toLowerCase().contains(model),
    );
  }
}

/// Temperature range specification
class _TemperatureRange {
  final double min;
  final double max;
  final double warningThreshold;

  const _TemperatureRange({
    required this.min,
    required this.max,
    required this.warningThreshold,
  });
}
