/// Heating status indicator widget
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../device/domain/entities/sauna_controller.dart';

/// Heating status indicator
///
/// Shows current heating status with icon and label
class HeatingStatusWidget extends StatelessWidget {
  final HeatingStatus status;

  const HeatingStatusWidget({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      HeatingStatus.heating => (Icons.whatshot, Colors.orange, 'Heating'),
      HeatingStatus.idle => (Icons.ac_unit, Colors.blue, 'Idle'),
      HeatingStatus.cooling => (Icons.air, Colors.lightBlue, 'Cooling'),
      HeatingStatus.targetReached => (
        Icons.check_circle,
        Colors.green,
        'At Target',
      ),
      HeatingStatus.unknown => (Icons.help_outline, Colors.grey, 'Unknown'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: LayoutConstants.iconSizeSmall, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
