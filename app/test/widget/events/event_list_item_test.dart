/// Widget tests for Event List Item
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvia_msga/features/events/domain/entities/event.dart';
import 'package:harvia_msga/features/events/presentation/widgets/event_list_item.dart';

void main() {
  group('EventListItem Widget Tests', () {
    final mockEvent = Event(
      eventId: 'evt-001',
      deviceId: 'dev-001',
      type: EventType.error,
      severity: Severity.high,
      title: 'Overheating Detected',
      message: 'Temperature exceeded safe limits',
      timestamp: DateTime(2024, 1, 15, 10, 30),
      metadata: const {'threshold': '110'},
      acknowledged: false,
    );

    testWidgets('should render event title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: mockEvent, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Overheating Detected'), findsOneWidget);
    });

    testWidgets('should render event message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: mockEvent, onTap: () {}),
            ),
          ),
        ),
      );

      expect(find.text('Temperature exceeded safe limits'), findsOneWidget);
    });

    testWidgets('should render formatted timestamp', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: mockEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should show formatted date/time
      expect(find.textContaining('Jan 15'), findsOneWidget);
      expect(find.textContaining('10:30'), findsOneWidget);
    });

    testWidgets('should display severity badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: mockEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should show severity indicator
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('should display event type icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: mockEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should show error icon for error type
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should show acknowledged indicator when acknowledged', (
      tester,
    ) async {
      final acknowledgedEvent = Event(
        eventId: 'evt-002',
        deviceId: 'dev-001',
        type: EventType.warning,
        severity: Severity.medium,
        title: 'Test Event',
        message: 'Test message',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        metadata: const {},
        acknowledged: true,
        acknowledgedAt: DateTime(2024, 1, 15, 10, 35),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: acknowledgedEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should show checkmark icon or "Acknowledged" badge
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
      'should not show acknowledged indicator when not acknowledged',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EventListItem(event: mockEvent, onTap: () {}),
              ),
            ),
          ),
        );

        // Should not show acknowledged indicator
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );

    testWidgets('should call onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(
                event: mockEvent,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the list item
      await tester.tap(find.byType(EventListItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('should use correct color for critical severity', (
      tester,
    ) async {
      final criticalEvent = Event(
        eventId: 'evt-003',
        deviceId: 'dev-001',
        type: EventType.error,
        severity: Severity.critical,
        title: 'Critical Event',
        message: 'Critical message',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        metadata: const {},
        acknowledged: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: criticalEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should have red color indicator for critical
      final severityBadge = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == Colors.red,
      );

      expect(severityBadge, findsOneWidget);
    });

    testWidgets('should use correct icon for warning type', (tester) async {
      final warningEvent = Event(
        eventId: 'evt-004',
        deviceId: 'dev-001',
        type: EventType.warning,
        severity: Severity.medium,
        title: 'Warning Event',
        message: 'Warning message',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        metadata: const {},
        acknowledged: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: warningEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should show warning icon
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should use correct icon for info type', (tester) async {
      final infoEvent = Event(
        eventId: 'evt-005',
        deviceId: 'dev-001',
        type: EventType.info,
        severity: Severity.info,
        title: 'Info Event',
        message: 'Info message',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        metadata: const {},
        acknowledged: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(event: infoEvent, onTap: () {}),
            ),
          ),
        ),
      );

      // Should show info icon
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('should show device ID when available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(
                event: mockEvent,
                onTap: () {},
                showDeviceId: true,
              ),
            ),
          ),
        ),
      );

      // Should show device ID
      expect(find.textContaining('dev-001'), findsOneWidget);
    });

    testWidgets('should not show device ID when showDeviceId is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EventListItem(
                event: mockEvent,
                onTap: () {},
                showDeviceId: false,
              ),
            ),
          ),
        ),
      );

      // Should not show device ID as standalone element
      // (may still appear in metadata)
      expect(find.text('Device: dev-001'), findsNothing);
    });
  });
}
