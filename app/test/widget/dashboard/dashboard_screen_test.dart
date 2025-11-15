/// Widget test for DashboardScreen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:harvia_msga/features/dashboard/presentation/providers/device_list_provider.dart';
import 'package:harvia_msga/features/device/domain/entities/sauna_controller.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    testWidgets('should display empty state when no devices', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceListProvider.overrideWith(
              (ref) => Future.value(<SaunaController>[]),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No devices found'), findsOneWidget);
      expect(find.byIcon(Icons.devices_other), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DashboardScreen())),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display device list when devices available', (
      tester,
    ) async {
      final mockDevices = [
        const SaunaController(
          deviceId: 'device1',
          name: 'Sauna 1',
          modelNumber: 'Harvia Xenio',
          serialNumber: 'SN001',
          powerState: PowerState.on,
          heatingStatus: HeatingStatus.heating,
          connectionStatus: ConnectionStatus.online,
          currentTemperature: 75.0,
          targetTemperature: 80.0,
          linkedSensorIds: [],
        ),
        const SaunaController(
          deviceId: 'device2',
          name: 'Sauna 2',
          modelNumber: 'Harvia Cilindro',
          serialNumber: 'SN002',
          powerState: PowerState.off,
          heatingStatus: HeatingStatus.idle,
          connectionStatus: ConnectionStatus.online,
          linkedSensorIds: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceListProvider.overrideWith((ref) => Future.value(mockDevices)),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should display device cards
      expect(find.text('Sauna 1'), findsOneWidget);
      expect(find.text('Sauna 2'), findsOneWidget);
    });

    testWidgets('should have pull-to-refresh functionality', (tester) async {
      final mockDevices = [
        const SaunaController(
          deviceId: 'device1',
          name: 'Test Sauna',
          modelNumber: 'Harvia Xenio',
          serialNumber: 'SN001',
          powerState: PowerState.on,
          heatingStatus: HeatingStatus.heating,
          connectionStatus: ConnectionStatus.online,
          linkedSensorIds: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceListProvider.overrideWith((ref) => Future.value(mockDevices)),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should have RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should show refresh button in app bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DashboardScreen())),
      );

      await tester.pumpAndSettle();

      // Should have refresh icon button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should display dashboard title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DashboardScreen())),
      );

      await tester.pumpAndSettle();

      // Should show dashboard title in app bar
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('should render grid layout on wide screens', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      final mockDevices = [
        const SaunaController(
          deviceId: 'device1',
          name: 'Sauna 1',
          modelNumber: 'Harvia Xenio',
          serialNumber: 'SN001',
          powerState: PowerState.on,
          heatingStatus: HeatingStatus.heating,
          connectionStatus: ConnectionStatus.online,
          linkedSensorIds: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceListProvider.overrideWith((ref) => Future.value(mockDevices)),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should use GridView for wide screens
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should render list layout on narrow screens', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      final mockDevices = [
        const SaunaController(
          deviceId: 'device1',
          name: 'Sauna 1',
          modelNumber: 'Harvia Xenio',
          serialNumber: 'SN001',
          powerState: PowerState.on,
          heatingStatus: HeatingStatus.heating,
          connectionStatus: ConnectionStatus.online,
          linkedSensorIds: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceListProvider.overrideWith((ref) => Future.value(mockDevices)),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should use ListView for narrow screens
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display error state on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceListProvider.overrideWith(
              (ref) => Future.error(Exception('Failed to load devices')),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('Error loading devices'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
