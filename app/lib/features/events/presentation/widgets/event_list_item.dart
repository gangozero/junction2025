/// Event list item widget
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../domain/entities/event.dart';

/// Event list item widget
///
/// Displays a single event in the list with severity indicator, icon, and metadata
class EventListItem extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool showDeviceId;

  const EventListItem({
    required this.event,
    required this.onTap,
    this.showDeviceId = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(
        horizontal: LayoutConstants.spacingMedium,
        vertical: LayoutConstants.spacingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(LayoutConstants.spacingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event type icon with severity color
              _EventIcon(type: event.type, severity: event.severity),
              const SizedBox(width: LayoutConstants.spacingMedium),

              // Event details (title, message, timestamp)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and severity badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: LayoutConstants.spacingSmall),
                        _SeverityBadge(severity: event.severity),
                      ],
                    ),
                    const SizedBox(height: LayoutConstants.spacingSmall),

                    // Message
                    Text(
                      event.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: LayoutConstants.spacingSmall),

                    // Timestamp and device ID
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: LayoutConstants.iconSizeSmall,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(event.timestamp),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                        if (showDeviceId) ...[
                          const SizedBox(width: LayoutConstants.spacingMedium),
                          Icon(
                            Icons.device_hub,
                            size: LayoutConstants.iconSizeSmall,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.deviceId,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Acknowledged indicator
              if (event.acknowledged)
                const Padding(
                  padding: EdgeInsets.only(left: LayoutConstants.spacingSmall),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: LayoutConstants.iconSizeMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final eventDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (eventDate == today) {
      return 'Today ${DateFormat.Hm().format(timestamp)}';
    } else if (eventDate == yesterday) {
      return 'Yesterday ${DateFormat.Hm().format(timestamp)}';
    } else {
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    }
  }
}

/// Event type icon with severity color
class _EventIcon extends StatelessWidget {
  final EventType type;
  final Severity severity;

  const _EventIcon({required this.type, required this.severity});

  @override
  Widget build(BuildContext context) {
    final iconData = switch (type) {
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

    final iconColor = _getSeverityColor(severity);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: LayoutConstants.iconSizeMedium,
      ),
    );
  }

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

/// Severity badge
class _SeverityBadge extends StatelessWidget {
  final Severity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final label = switch (severity) {
      Severity.critical => 'CRITICAL',
      Severity.high => 'HIGH',
      Severity.medium => 'MEDIUM',
      Severity.low => 'LOW',
      Severity.info => 'INFO',
    };

    final backgroundColor = switch (severity) {
      Severity.critical => Colors.red,
      Severity.high => Colors.deepOrange,
      Severity.medium => Colors.orange,
      Severity.low => Colors.blue,
      Severity.info => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
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
