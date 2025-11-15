/// Widget tests for SensorLinkDialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/device/presentation/widgets/sensor_link_dialog.dart';
import 'package:harvia_msga/features/device/domain/entities/sensor_device.dart';

void main() {
  group('SensorLinkDialog Widget Tests', () {
    final mockSensors = [
      SensorDevice(
        deviceId: 'sensor-1',
        name: 'Temperature Sensor 1',
        type: SensorType.temperature,
        temperature: 22.5,
        batteryLevel: 85,
        isOnline: true,
      ),
      SensorDevice(
        deviceId: 'sensor-2',
        name: 'TH Sensor 2',
        type: SensorType.temperatureHumidity,
        temperature: 23.0,
        humidity: 45.0,
        batteryLevel: 15,
        isOnline: true,
      ),
      SensorDevice(
        deviceId: 'sensor-3',
        name: 'Offline Sensor',
        type: SensorType.temperature,
        batteryLevel: 50,
        isOnline: false,
      ),
    ];

    testWidgets('should display dialog title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Link Sensor'), findsOneWidget);
    });

    testWidgets('should display instruction text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(
        find.text('Select a sensor to link to this controller:'),
        findsOneWidget,
      );
    });

    testWidgets('should display all available sensors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Temperature Sensor 1'), findsOneWidget);
      expect(find.text('TH Sensor 2'), findsOneWidget);
      expect(find.text('Offline Sensor'), findsOneWidget);
    });

    testWidgets('should display sensor temperature data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('22.5°C'), findsOneWidget);
      expect(find.textContaining('23.0°C'), findsOneWidget);
    });

    testWidgets('should display humidity for TH sensors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('45%'), findsOneWidget);
    });

    testWidgets('should display battery level', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Battery: 85%'), findsOneWidget);
    });

    testWidgets('should show battery alert icon for low battery',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Sensor-2 has 15% battery (low)
      expect(find.byIcon(Icons.battery_alert), findsOneWidget);
    });

    testWidgets('should display offline status', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline'), findsOneWidget);
    });

    testWidgets('should show "No available sensors" when list is empty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: [],
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('No available sensors found'), findsOneWidget);
    });

    testWidgets('should display Cancel button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should display Link button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Link'), findsOneWidget);
    });

    testWidgets('Link button should be disabled initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final linkButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Link'),
          matching: find.byType(FilledButton),
        ),
      );

      expect(linkButton.onPressed, isNull);
    });

    testWidgets('should select sensor on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap first sensor
      await tester.tap(find.text('Temperature Sensor 1'));
      await tester.pumpAndSettle();

      // Link button should now be enabled
      final linkButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Link'),
          matching: find.byType(FilledButton),
        ),
      );

      expect(linkButton.onPressed, isNotNull);
    });

    testWidgets('should close dialog on Cancel', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Link Sensor'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Link Sensor'), findsNothing);
    });

    testWidgets('should display appropriate icons for sensor types',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => SensorLinkDialog(
                        controllerId: 'controller-1',
                        availableSensors: mockSensors,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Temperature sensor icon
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
      // TH sensor icon
      expect(find.byIcon(Icons.sensors), findsOneWidget);
    });
  });
}
