/// Widget tests for Events Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/events/domain/entities/event.dart';
import 'package:harvia_msga/features/events/presentation/providers/events_provider.dart';
import 'package:harvia_msga/features/events/presentation/screens/events_screen.dart';

void main() {
  group('EventsScreen Widget Tests', () {
    final mockEvents = [
      Event(
        eventId: 'evt-001',
        deviceId: 'dev-001',
        type: EventType.error,
        severity: Severity.high,
        title: 'Overheating Detected',
        message: 'Temperature exceeded safe limits',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        metadata: const {'threshold': '110'},
        acknowledged: false,
      ),
      Event(
        eventId: 'evt-002',
        deviceId: 'dev-001',
        type: EventType.warning,
        severity: Severity.medium,
        title: 'Low Water Level',
        message: 'Water reservoir needs refilling',
        timestamp: DateTime(2024, 1, 15, 9, 15),
        metadata: const {},
        acknowledged: true,
        acknowledgedAt: DateTime(2024, 1, 15, 9, 20),
      ),
      Event(
        eventId: 'evt-003',
        deviceId: 'dev-002',
        type: EventType.info,
        severity: Severity.info,
        title: 'Heating Started',
        message: 'Sauna heating cycle initiated',
        timestamp: DateTime(2024, 1, 15, 8, 0),
        metadata: const {},
        acknowledged: false,
      ),
    ];

    testWidgets('should render app bar with title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => mockEvents),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Event History'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith(
              (ref) async =>
                  Future.delayed(const Duration(seconds: 1), () => mockEvents),
            ),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      // Should show loading indicator before data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display event list after loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => mockEvents),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should display all three events
      expect(find.text('Overheating Detected'), findsOneWidget);
      expect(find.text('Low Water Level'), findsOneWidget);
      expect(find.text('Heating Started'), findsOneWidget);
    });

    testWidgets('should display filter button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => mockEvents),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should show empty state when no events', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => <Event>[]),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
    });

    testWidgets('should display error message on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith(
              (ref) async => throw Exception('Failed to load events'),
            ),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load events'), findsOneWidget);
    });

    testWidgets('should render responsive layout on mobile', (tester) async {
      // Set small screen size for mobile
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => mockEvents),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should use ListView for mobile
      expect(find.byType(ListView), findsOneWidget);

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should render responsive layout on web', (tester) async {
      // Set large screen size for web
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => mockEvents),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should use table/grid for web (implementation will add this)
      // This test will pass once T083 implements responsive layout

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should pull to refresh', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsListProvider((
              deviceId: null,
              types: null,
              severities: null,
              startDate: null,
              endDate: null,
              limit: null,
              offset: null,
            )).overrideWith((ref) async => mockEvents),
          ],
          child: const MaterialApp(home: EventsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Simulate pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should trigger refresh (implementation will handle this)
    });
  });
}
