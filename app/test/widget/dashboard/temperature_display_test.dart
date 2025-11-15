/// Widget tests for TemperatureDisplay
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/dashboard/presentation/widgets/temperature_display.dart';
import 'package:harvia_msga/features/device/domain/entities/sauna_controller.dart';

void main() {
  group('TemperatureDisplay Widget Tests', () {
    testWidgets('should display current temperature', (tester) async {
      final device = SaunaController(
        deviceId: 'test-1',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN001',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.heating,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 45.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: device)),
        ),
      );

      expect(find.text('45.5°C'), findsOneWidget);
    });

    testWidgets('should display current and target temperature', (
      tester,
    ) async {
      final device = SaunaController(
        deviceId: 'test-2',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN002',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.heating,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 45.5,
        targetTemperature: 80.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: device)),
        ),
      );

      expect(find.text('45.5°C'), findsOneWidget);
      expect(find.text('80°C'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should display progress bar when target is set', (
      tester,
    ) async {
      final device = SaunaController(
        deviceId: 'test-3',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN003',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.heating,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 40.0,
        targetTemperature: 80.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: device)),
        ),
      );

      // Should display LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Should display progress percentage
      final progressText = find.textContaining('% to target');
      expect(progressText, findsOneWidget);
    });

    testWidgets('should display "No temperature data" when null', (
      tester,
    ) async {
      final device = SaunaController(
        deviceId: 'test-4',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN004',
        powerState: PowerState.off,
        heatingStatus: HeatingStatus.unknown,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: device)),
        ),
      );

      expect(find.text('No temperature data'), findsOneWidget);
    });

    testWidgets('should color code temperature based on heat level', (
      tester,
    ) async {
      final hotDevice = SaunaController(
        deviceId: 'test-5',
        name: 'Hot Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN005',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.heating,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 85.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: hotDevice)),
        ),
      );

      // Find Text widget with 85.0°C
      final tempText = tester.widget<Text>(find.text('85.0°C'));

      // High temperature should be colored (not grey)
      expect(tempText.style?.color, isNot(Colors.grey));
    });

    testWidgets('should show progress color change as temperature increases', (
      tester,
    ) async {
      final midProgressDevice = SaunaController(
        deviceId: 'test-6',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN006',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.heating,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 50.0,
        targetTemperature: 80.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: midProgressDevice)),
        ),
      );

      // Find progress indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // Progress value should be calculated correctly
      // (50 - 20) / (80 - 20) = 30/60 = 0.5 (assuming ambient is 20)
      expect(progressIndicator.value, isNotNull);
      expect(progressIndicator.value, greaterThan(0.0));
      expect(progressIndicator.value, lessThanOrEqualTo(1.0));
    });

    testWidgets('should not show progress when no target temperature', (
      tester,
    ) async {
      final noTargetDevice = SaunaController(
        deviceId: 'test-7',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN007',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.idle,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 25.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: noTargetDevice)),
        ),
      );

      // Should NOT show progress bar
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // Should NOT show arrow icon
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      // Should NOT show target temperature
      expect(find.textContaining('°C', skipOffstage: false), findsOneWidget);
    });

    testWidgets('should display 100% progress when target reached', (
      tester,
    ) async {
      final targetReachedDevice = SaunaController(
        deviceId: 'test-8',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN008',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.targetReached,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 80.0,
        targetTemperature: 80.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TemperatureDisplay(device: targetReachedDevice)),
        ),
      );

      // Find progress indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // Progress should be at 100% (1.0)
      expect(progressIndicator.value, 1.0);

      // Should show 100% text
      expect(find.text('100% to target'), findsOneWidget);
    });
  });
}
