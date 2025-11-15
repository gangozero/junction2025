/// Widget tests for DeviceStatusCard
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/dashboard/presentation/providers/device_state_provider.dart';
import 'package:harvia_msga/features/dashboard/presentation/widgets/device_status_card.dart';
import 'package:harvia_msga/features/device/domain/entities/sauna_controller.dart';

void main() {
  group('DeviceStatusCard Widget Tests', () {
    final mockDevice = SaunaController(
      deviceId: 'test-device-1',
      name: 'Test Sauna',
      modelNumber: 'Harvia Xenio CX170',
      serialNumber: 'SN001',
      powerState: PowerState.on,
      heatingStatus: HeatingStatus.heating,
      connectionStatus: ConnectionStatus.online,
      linkedSensorIds: const <String>[],
      currentTemperature: 45.5,
      targetTemperature: 80.0,
    );

    testWidgets('should render device name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      expect(find.text('Test Sauna'), findsOneWidget);
    });

    testWidgets('should render model number', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      expect(find.text('Harvia Xenio CX170'), findsOneWidget);
    });

    testWidgets('should display online connection status indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      // Find the green circle icon indicating online status
      final onlineIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.circle &&
            widget.color == Colors.green,
      );
      expect(onlineIcon, findsOneWidget);
    });

    testWidgets('should display offline connection status indicator', (
      tester,
    ) async {
      final offlineDevice = SaunaController(
        deviceId: 'test-device-2',
        name: 'Offline Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN002',
        powerState: PowerState.off,
        heatingStatus: HeatingStatus.unknown,
        connectionStatus: ConnectionStatus.offline,
        linkedSensorIds: const <String>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-2',
            ).overrideWith((ref) => Stream.value(offlineDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: offlineDevice)),
          ),
        ),
      );

      // Find the red circle icon indicating offline status
      final offlineIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.circle &&
            widget.color == Colors.red,
      );
      expect(offlineIcon, findsOneWidget);
    });

    testWidgets('should display temperature data when available', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      // Should render TemperatureDisplay widget
      expect(find.text('45.5°C'), findsOneWidget);
    });

    testWidgets('should display "No temperature data" when unavailable', (
      tester,
    ) async {
      final noTempDevice = SaunaController(
        deviceId: 'test-device-3',
        name: 'No Temp Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN003',
        powerState: PowerState.off,
        heatingStatus: HeatingStatus.unknown,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-3',
            ).overrideWith((ref) => Stream.value(noTempDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: noTempDevice)),
          ),
        ),
      );

      expect(find.text('No temperature data'), findsOneWidget);
    });

    testWidgets('should display heating status indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      // Should render HeatingStatusWidget with "Heating" label
      expect(find.text('Heating'), findsOneWidget);
    });

    testWidgets('should display power ON indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      // Find power ON icon
      final powerOnIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.power_settings_new &&
            widget.color == Colors.green,
      );
      expect(powerOnIcon, findsOneWidget);
    });

    testWidgets('should display power OFF indicator', (tester) async {
      final powerOffDevice = SaunaController(
        deviceId: 'test-device-4',
        name: 'Off Sauna',
        modelNumber: 'Harvia Xenio',
        serialNumber: 'SN004',
        powerState: PowerState.off,
        heatingStatus: HeatingStatus.idle,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-4',
            ).overrideWith((ref) => Stream.value(powerOffDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: powerOffDevice)),
          ),
        ),
      );

      // Find power OFF icon
      final powerOffIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.power_settings_new &&
            widget.color == Colors.grey,
      );
      expect(powerOffIcon, findsOneWidget);
    });

    testWidgets('should be wrapped in Card and InkWell for tap interaction', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(mockDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should update when real-time data arrives', (tester) async {
      final updatedDevice = SaunaController(
        deviceId: 'test-device-1',
        name: 'Test Sauna',
        modelNumber: 'Harvia Xenio CX170',
        serialNumber: 'SN001',
        powerState: PowerState.on,
        heatingStatus: HeatingStatus.targetReached,
        connectionStatus: ConnectionStatus.online,
        linkedSensorIds: const <String>[],
        currentTemperature: 80.0,
        targetTemperature: 80.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateStreamProvider(
              'test-device-1',
            ).overrideWith((ref) => Stream.value(updatedDevice)),
          ],
          child: MaterialApp(
            home: Scaffold(body: DeviceStatusCard(device: mockDevice)),
          ),
        ),
      );

      await tester.pump();

      // Should show updated temperature
      expect(find.text('80.0°C'), findsOneWidget);
      // Should show updated heating status
      expect(find.text('At Target'), findsOneWidget);
    });
  });
}
