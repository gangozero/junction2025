/// Widget tests for HumidityDisplay
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/dashboard/presentation/widgets/humidity_display.dart';
import 'package:harvia_msga/features/device/domain/entities/sensor_device.dart';

void main() {
  group('HumidityDisplay Widget Tests', () {
    testWidgets('should display humidity value for temp+humidity sensor', (
      tester,
    ) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-1',
        name: 'Humidity Sensor',
        type: SensorType.temperatureHumidity,
        temperature: 45.0,
        humidity: 35.5,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      expect(find.text('35.5%'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
    });

    testWidgets('should display water drop icon', (tester) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-2',
        name: 'TH Sensor',
        type: SensorType.temperatureHumidity,
        temperature: 50.0,
        humidity: 40.0,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('should not display for temperature-only sensor', (
      tester,
    ) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-3',
        name: 'Temp Sensor',
        type: SensorType.temperature,
        temperature: 55.0,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      // Should render nothing (SizedBox.shrink)
      expect(find.byType(Container), findsNothing);
      expect(find.text('Humidity'), findsNothing);
    });

    testWidgets('should not display when humidity is null', (tester) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-4',
        name: 'TH Sensor No Data',
        type: SensorType.temperatureHumidity,
        temperature: 45.0,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      // Should render nothing when humidity is null
      expect(find.text('Humidity'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('should display with blue color theme', (tester) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-5',
        name: 'TH Sensor',
        type: SensorType.temperatureHumidity,
        temperature: 48.0,
        humidity: 45.0,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      // Find the Container widget
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;

      // Should have blue-themed background and border
      expect(decoration.color, Colors.blue.withOpacity(0.1));
      expect(decoration.border, isNotNull);
    });

    testWidgets('should format humidity with one decimal place', (
      tester,
    ) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-6',
        name: 'TH Sensor',
        type: SensorType.temperatureHumidity,
        temperature: 50.0,
        humidity: 42.567,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      // Should round to 1 decimal place
      expect(find.text('42.6%'), findsOneWidget);
    });

    testWidgets('should display correctly for high humidity', (tester) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-7',
        name: 'High Humidity Sensor',
        type: SensorType.temperatureHumidity,
        temperature: 35.0,
        humidity: 95.2,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      expect(find.text('95.2%'), findsOneWidget);
    });

    testWidgets('should display correctly for low humidity', (tester) async {
      final sensor = SensorDevice(
        deviceId: 'sensor-8',
        name: 'Low Humidity Sensor',
        type: SensorType.temperatureHumidity,
        temperature: 60.0,
        humidity: 5.0,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HumidityDisplay(sensor: sensor)),
        ),
      );

      expect(find.text('5.0%'), findsOneWidget);
    });
  });
}
