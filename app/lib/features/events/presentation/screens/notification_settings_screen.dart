/// Notification settings screen
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../services/notifications/event_notification_handler.dart';
import '../../domain/entities/event.dart';

/// Notification settings screen
///
/// Allows users to configure which event types trigger notifications
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _notificationHandler = EventNotificationHandler();

  late Set<EventType> _enabledTypes;
  late Severity _minimumSeverity;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _enabledTypes = Set.from(_notificationHandler.enabledEventTypes);
    _minimumSeverity = _notificationHandler.minimumSeverity;
    _hasPermission = _notificationHandler.hasNotificationPermission;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(LayoutConstants.paddingMobile),
        children: [
          // Permission status
          _PermissionCard(
            hasPermission: _hasPermission,
            onRequestPermission: _requestPermission,
          ),
          const SizedBox(height: LayoutConstants.spacingLarge),

          // Minimum severity
          Text(
            'Minimum Severity Level',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LayoutConstants.spacingSmall),
          const Text(
            'Only show notifications for events at or above this severity level',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: LayoutConstants.spacingMedium),
          ...Severity.values.map((severity) {
            return RadioListTile<Severity>(
              title: Text(_getSeverityLabel(severity)),
              subtitle: Text(_getSeverityDescription(severity)),
              value: severity,
              groupValue: _minimumSeverity,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _minimumSeverity = value;
                    _notificationHandler.setMinimumSeverity(value);
                  });
                }
              },
            );
          }),
          const SizedBox(height: LayoutConstants.spacingLarge),

          // Event types
          Text(
            'Enabled Event Types',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: LayoutConstants.spacingSmall),
          const Text(
            'Select which types of events trigger notifications',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: LayoutConstants.spacingMedium),
          ...EventType.values.map((type) {
            return CheckboxListTile(
              title: Text(_getEventTypeLabel(type)),
              subtitle: Text(_getEventTypeDescription(type)),
              value: _enabledTypes.contains(type),
              onChanged: (enabled) {
                setState(() {
                  if (enabled == true) {
                    _enabledTypes.add(type);
                  } else {
                    _enabledTypes.remove(type);
                  }
                  _notificationHandler.setEnabledEventTypes(_enabledTypes);
                });
              },
            );
          }),
          const SizedBox(height: LayoutConstants.spacingLarge),

          // Save button
          ElevatedButton(
            onPressed: () {
              // Settings are saved automatically
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings saved'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final granted = await _notificationHandler.requestPermissions();

    setState(() {
      _hasPermission = granted;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Notification permissions granted'
              : 'Notification permissions denied',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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

  /// Get severity description
  String _getSeverityDescription(Severity severity) {
    return switch (severity) {
      Severity.critical => 'Only critical system failures',
      Severity.high => 'Important errors and warnings',
      Severity.medium => 'Moderate issues and alerts',
      Severity.low => 'Minor issues and updates',
      Severity.info => 'All events including informational',
    };
  }

  /// Get event type label
  String _getEventTypeLabel(EventType type) {
    return switch (type) {
      EventType.error => 'Errors',
      EventType.warning => 'Warnings',
      EventType.info => 'Info',
      EventType.temperatureAlert => 'Temperature Alerts',
      EventType.connectionChange => 'Connection Changes',
      EventType.commandFailed => 'Command Failures',
      EventType.commandExecuted => 'Command Executions',
      EventType.stateChange => 'State Changes',
      EventType.unknown => 'Unknown Events',
    };
  }

  /// Get event type description
  String _getEventTypeDescription(EventType type) {
    return switch (type) {
      EventType.error => 'System errors and failures',
      EventType.warning => 'Warning messages',
      EventType.info => 'Informational messages',
      EventType.temperatureAlert => 'Temperature threshold alerts',
      EventType.connectionChange => 'Device connection status changes',
      EventType.commandFailed => 'Failed control commands',
      EventType.commandExecuted => 'Successful command executions',
      EventType.stateChange => 'Device state changes',
      EventType.unknown => 'Unrecognized event types',
    };
  }
}

/// Permission status card
class _PermissionCard extends StatelessWidget {
  final bool hasPermission;
  final VoidCallback onRequestPermission;

  const _PermissionCard({
    required this.hasPermission,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: hasPermission ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(LayoutConstants.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasPermission ? Icons.check_circle : Icons.warning,
                  color: hasPermission ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPermission
                      ? 'Notifications Enabled'
                      : 'Notifications Disabled',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: hasPermission ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasPermission
                  ? 'You will receive notifications for enabled event types'
                  : 'Grant notification permissions to receive alerts',
              style: const TextStyle(color: Colors.grey),
            ),
            if (!hasPermission) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Enable Notifications'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
