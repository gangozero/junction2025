/// Event filter widget
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../domain/entities/event.dart';

/// Event filter widget
///
/// Provides filtering controls for events by type, severity, and date range
class EventFilter extends StatefulWidget {
  final Set<EventType> selectedTypes;
  final Set<Severity> selectedSeverities;
  final void Function(
    Set<EventType> types,
    Set<Severity> severities,
    DateTime? startDate,
    DateTime? endDate,
  )
  onFilterChanged;

  const EventFilter({
    required this.selectedTypes,
    required this.selectedSeverities,
    required this.onFilterChanged,
    super.key,
  });

  @override
  State<EventFilter> createState() => _EventFilterState();
}

class _EventFilterState extends State<EventFilter> {
  late Set<EventType> _selectedTypes;
  late Set<Severity> _selectedSeverities;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.selectedTypes);
    _selectedSeverities = Set.from(widget.selectedSeverities);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(LayoutConstants.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with active filter count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                if (_getActiveFilterCount() > 0)
                  Chip(
                    label: Text('${_getActiveFilterCount()} active filters'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: LayoutConstants.spacingMedium),

            // Event Types
            Text('Event Types', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: LayoutConstants.spacingSmall),
            Wrap(
              spacing: LayoutConstants.spacingSmall,
              children: EventType.values.map((type) {
                return FilterChip(
                  label: Text(_getEventTypeLabel(type)),
                  selected: _selectedTypes.contains(type),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                      _notifyFilterChanged();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: LayoutConstants.spacingMedium),

            // Severity Levels
            Text('Severity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: LayoutConstants.spacingSmall),
            Wrap(
              spacing: LayoutConstants.spacingSmall,
              children: Severity.values.map((severity) {
                return FilterChip(
                  label: Text(_getSeverityLabel(severity)),
                  selected: _selectedSeverities.contains(severity),
                  backgroundColor: _getSeverityColor(severity).withOpacity(0.1),
                  selectedColor: _getSeverityColor(severity).withOpacity(0.3),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSeverities.add(severity);
                      } else {
                        _selectedSeverities.remove(severity);
                      }
                      _notifyFilterChanged();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: LayoutConstants.spacingMedium),

            // Date Range
            Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: LayoutConstants.spacingSmall),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(_getDateRangeLabel()),
                  ),
                ),
                if (_startDate != null || _endDate != null) ...[
                  const SizedBox(width: LayoutConstants.spacingSmall),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _notifyFilterChanged();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear date range',
                  ),
                ],
              ],
            ),
            const SizedBox(height: LayoutConstants.spacingLarge),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(width: LayoutConstants.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Select date range
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _notifyFilterChanged();
      });
    }
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedSeverities.clear();
      _startDate = null;
      _endDate = null;
      _notifyFilterChanged();
    });
  }

  /// Notify parent of filter changes
  void _notifyFilterChanged() {
    widget.onFilterChanged(
      _selectedTypes,
      _selectedSeverities,
      _startDate,
      _endDate,
    );
  }

  /// Get active filter count
  int _getActiveFilterCount() {
    var count = 0;
    count += _selectedTypes.length;
    count += _selectedSeverities.length;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }

  /// Get date range label
  String _getDateRangeLabel() {
    if (_startDate != null && _endDate != null) {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${_formatDate(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${_formatDate(_endDate!)}';
    } else {
      return 'Select Date Range';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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

  /// Get severity label
  String _getSeverityLabel(Severity severity) {
    return switch (severity) {
      Severity.critical => 'Critical',
      Severity.high => 'High',
      Severity.medium => 'Medium',
      Severity.low => 'Low',
      Severity.info => 'Info',
    };
  }

  /// Get severity color
  Color _getSeverityColor(Severity severity) {
    return switch (severity) {
      Severity.critical => Colors.red,
      Severity.high => Colors.deepOrange,
      Severity.medium => Colors.orange,
      Severity.low => Colors.blue,
      Severity.info => Colors.grey,
    };
  }
}
