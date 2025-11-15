/// Widget tests for Event Filter
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/events/domain/entities/event.dart';
import 'package:harvia_msga/features/events/presentation/widgets/event_filter.dart';

void main() {
  group('EventFilter Widget Tests', () {
    testWidgets('should render all filter controls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have event type filter
      expect(find.text('Event Types'), findsOneWidget);

      // Should have severity filter
      expect(find.text('Severity'), findsOneWidget);

      // Should have date range filter
      expect(find.text('Date Range'), findsOneWidget);
    });

    testWidgets('should display all event type options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all event types as checkboxes
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Temperature Alert'), findsOneWidget);
      expect(find.text('Connection Change'), findsOneWidget);
    });

    testWidgets('should display all severity options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all severity levels
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('should toggle event type checkbox', (tester) async {
      var capturedTypes = <EventType>{};

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {
                  capturedTypes = types;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap error checkbox
      await tester.tap(find.text('Error'));
      await tester.pumpAndSettle();

      // Should call callback with error type selected
      expect(capturedTypes, contains(EventType.error));
    });

    testWidgets('should toggle severity checkbox', (tester) async {
      var capturedSeverities = <Severity>{};

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {
                  capturedSeverities = severities;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap critical checkbox
      await tester.tap(find.text('Critical'));
      await tester.pumpAndSettle();

      // Should call callback with critical severity selected
      expect(capturedSeverities, contains(Severity.critical));
    });

    testWidgets('should display clear filters button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('should clear all filters when clear button tapped', (
      tester,
    ) async {
      var capturedTypes = <EventType>{};
      var capturedSeverities = <Severity>{};

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: {EventType.error, EventType.warning},
                selectedSeverities: {Severity.high},
                onFilterChanged: (types, severities, startDate, endDate) {
                  capturedTypes = types;
                  capturedSeverities = severities;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap clear filters button
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      // Should call callback with empty sets
      expect(capturedTypes, isEmpty);
      expect(capturedSeverities, isEmpty);
    });

    testWidgets('should show date range picker when date button tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: const {},
                selectedSeverities: const {},
                onFilterChanged: (types, severities, startDate, endDate) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap date range button
      await tester.tap(find.text('Select Date Range'));
      await tester.pumpAndSettle();

      // Should open date range picker dialog
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });

    testWidgets('should show selected filters count badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventFilter(
                selectedTypes: {EventType.error, EventType.warning},
                selectedSeverities: {Severity.high, Severity.critical},
                onFilterChanged: (types, severities, startDate, endDate) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show count of active filters (2 types + 2 severities = 4)
      expect(find.text('4 active filters'), findsOneWidget);
    });
  });
}
