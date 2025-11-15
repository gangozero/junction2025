/// Events history screen with responsive layout
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../domain/entities/event.dart';
import '../providers/events_provider.dart';
import '../widgets/event_filter.dart';
import '../widgets/event_list_item.dart';

/// Events screen
///
/// Displays event history with filtering and responsive layout:
/// - Mobile: Single column list
/// - Web: Table view with sortable columns
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  Set<EventType> _selectedTypes = {};
  Set<Severity> _selectedSeverities = {};
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth >= LayoutConstants.desktopBreakpoint;

    // Build filter parameters
    final filterParams = (
      deviceId: null,
      types: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
      severities: _selectedSeverities.isNotEmpty
          ? _selectedSeverities.toList()
          : null,
      startDate: _startDate,
      endDate: _endDate,
      limit: null,
      offset: null,
    );

    final eventsAsync = ref.watch(eventsListProvider(filterParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event History'),
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter events',
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(eventsListProvider(filterParams)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No events found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventsListProvider(filterParams));
              await ref.read(eventsListProvider(filterParams).future);
            },
            child: isWebLayout
                ? _buildTableView(events)
                : _buildListView(events),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(eventsListProvider(filterParams)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build mobile/tablet list view
  Widget _buildListView(List<Event> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: LayoutConstants.spacingMedium,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventListItem(
          event: event,
          showDeviceId: true,
          onTap: () => _showEventDetails(event),
        );
      },
    );
  }

  /// Build web table view
  Widget _buildTableView(List<Event> events) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LayoutConstants.paddingDesktop),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Severity')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Message')),
            DataColumn(label: Text('Device')),
            DataColumn(label: Text('Status')),
          ],
          rows: events.map((event) {
            return DataRow(
              cells: [
                DataCell(Text(_formatTimestamp(event.timestamp))),
                DataCell(
                  Row(
                    children: [
                      Icon(_getEventIcon(event.type), size: 16),
                      const SizedBox(width: 4),
                      Text(_getEventTypeLabel(event.type)),
                    ],
                  ),
                ),
                DataCell(_buildSeverityBadge(event.severity)),
                DataCell(Text(event.title, overflow: TextOverflow.ellipsis)),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      event.message,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(Text(event.deviceId)),
                DataCell(
                  event.acknowledged
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                ),
              ],
              onSelectChanged: (_) => _showEventDetails(event),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: EventFilter(
            selectedTypes: _selectedTypes,
            selectedSeverities: _selectedSeverities,
            onFilterChanged: (types, severities, startDate, endDate) {
              setState(() {
                _selectedTypes = types;
                _selectedSeverities = severities;
                _startDate = startDate;
                _endDate = endDate;
              });
            },
          ),
        );
      },
    );
  }

  /// Show event details dialog
  void _showEventDetails(Event event) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getEventIcon(event.type)),
              const SizedBox(width: 8),
              Expanded(child: Text(event.title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(label: 'Message', value: event.message),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Time',
                  value: _formatTimestamp(event.timestamp),
                ),
                const SizedBox(height: 8),
                _DetailRow(label: 'Device ID', value: event.deviceId),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Type',
                  value: _getEventTypeLabel(event.type),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Severity',
                  value: event.severity
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase(),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Status',
                  value: event.acknowledged ? 'Acknowledged' : 'Pending',
                ),
                if (event.acknowledgedAt != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Acknowledged At',
                    value: _formatTimestamp(event.acknowledgedAt!),
                  ),
                ],
                if (event.metadata.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Metadata:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...event.metadata.entries.map(
                    (entry) => _DetailRow(
                      label: entry.key,
                      value: entry.value.toString(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!event.acknowledged)
              TextButton(
                onPressed: () {
                  _acknowledgeEvent(event.eventId);
                  Navigator.of(context).pop();
                },
                child: const Text('Acknowledge'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Acknowledge event
  void _acknowledgeEvent(String eventId) {
    ref.read(eventAcknowledgmentProvider.notifier).acknowledgeEvent(eventId);

    // Refresh events list
    final filterParams = (
      deviceId: null,
      types: _selectedTypes.isNotEmpty ? _selectedTypes.toList() : null,
      severities: _selectedSeverities.isNotEmpty
          ? _selectedSeverities.toList()
          : null,
      startDate: _startDate,
      endDate: _endDate,
      limit: null,
      offset: null,
    );
    ref.invalidate(eventsListProvider(filterParams));
  }

  /// Check if there are active filters
  bool _hasActiveFilters() {
    return _selectedTypes.isNotEmpty ||
        _selectedSeverities.isNotEmpty ||
        _startDate != null ||
        _endDate != null;
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Get event type icon
  IconData _getEventIcon(EventType type) {
    return switch (type) {
      EventType.error => Icons.error,
      EventType.warning => Icons.warning,
      EventType.info => Icons.info,
      EventType.temperatureAlert => Icons.thermostat,
      EventType.connectionChange => Icons.wifi,
      EventType.commandFailed => Icons.cancel,
      EventType.commandExecuted => Icons.check_circle_outline,
      EventType.stateChange => Icons.sync,
      EventType.unknown => Icons.help_outline,
    };
  }

  /// Get event type label
  String _getEventTypeLabel(EventType type) {
    return switch (type) {
      EventType.error => 'Error',
      EventType.warning => 'Warning',
      EventType.info => 'Info',
      EventType.temperatureAlert => 'Temperature Alert',
      EventType.connectionChange => 'Connection Change',
      EventType.commandFailed => 'Command Failed',
      EventType.commandExecuted => 'Command Executed',
      EventType.stateChange => 'State Change',
      EventType.unknown => 'Unknown',
    };
  }

  /// Build severity badge for table
  Widget _buildSeverityBadge(Severity severity) {
    final label = severity.toString().split('.').last.toUpperCase();
    final color = switch (severity) {
      Severity.critical => Colors.red,
      Severity.high => Colors.deepOrange,
      Severity.medium => Colors.orange,
      Severity.low => Colors.blue,
      Severity.info => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Detail row widget for event details dialog
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
