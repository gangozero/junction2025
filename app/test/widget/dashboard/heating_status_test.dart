/// Widget tests for HeatingStatusWidget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/dashboard/presentation/widgets/heating_status.dart';
import 'package:harvia_msga/features/device/domain/entities/sauna_controller.dart';

void main() {
  group('HeatingStatusWidget Tests', () {
    testWidgets('should display "Heating" for heating status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.heating),
          ),
        ),
      );

      expect(find.text('Heating'), findsOneWidget);
      expect(find.byIcon(Icons.whatshot), findsOneWidget);
    });

    testWidgets('should display orange color for heating status', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.heating),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.whatshot));
      expect(icon.color, Colors.orange);
    });

    testWidgets('should display "Idle" for idle status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeatingStatusWidget(status: HeatingStatus.idle)),
        ),
      );

      expect(find.text('Idle'), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    testWidgets('should display blue color for idle status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeatingStatusWidget(status: HeatingStatus.idle)),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.ac_unit));
      expect(icon.color, Colors.blue);
    });

    testWidgets('should display "Cooling" for cooling status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.cooling),
          ),
        ),
      );

      expect(find.text('Cooling'), findsOneWidget);
      expect(find.byIcon(Icons.air), findsOneWidget);
    });

    testWidgets('should display light blue color for cooling status', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.cooling),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.air));
      expect(icon.color, Colors.lightBlue);
    });

    testWidgets('should display "At Target" for target reached status', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.targetReached),
          ),
        ),
      );

      expect(find.text('At Target'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display green color for target reached status', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.targetReached),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);
    });

    testWidgets('should display "Unknown" for unknown status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.unknown),
          ),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('should display grey color for unknown status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.unknown),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.help_outline));
      expect(icon.color, Colors.grey);
    });

    testWidgets('should render as a Row widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.heating),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('should have icon and text aligned horizontally', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatingStatusWidget(status: HeatingStatus.heating),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
      expect(row.children.length, 3); // Icon, SizedBox, Text
    });
  });
}
