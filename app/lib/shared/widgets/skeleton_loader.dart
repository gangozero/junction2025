/// Loading skeleton widget
library;

import 'package:flutter/material.dart';

/// Skeleton loader widget
///
/// Displays animated loading placeholder for async content.
/// Provides better UX than spinners for list/card content.
class SkeletonLoader extends StatefulWidget {
  /// Width of skeleton (null for full width)
  final double? width;

  /// Height of skeleton
  final double height;

  /// Border radius
  final double borderRadius;

  /// Whether to animate
  final bool animate;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    this.animate = true,
  });

  /// Create skeleton for text line
  factory SkeletonLoader.text({Key? key, double? width, double height = 16}) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: 4,
    );
  }

  /// Create skeleton for card
  factory SkeletonLoader.card({Key? key, double? width, double height = 120}) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: 12,
    );
  }

  /// Create skeleton for circular avatar
  factory SkeletonLoader.circle({Key? key, double size = 48}) {
    return SkeletonLoader(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[700]!;
    final highlightColor = theme.brightness == Brightness.light
        ? Colors.grey[100]!
        : Colors.grey[600]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: widget.animate
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [baseColor, highlightColor, baseColor],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((s) => s.clamp(0.0, 1.0)).toList(),
                  )
                : null,
            color: widget.animate ? null : baseColor,
          ),
        );
      },
    );
  }
}

/// Skeleton list loader
///
/// Shows multiple skeleton items in a list
class SkeletonListLoader extends StatelessWidget {
  /// Number of skeleton items
  final int itemCount;

  /// Height of each item
  final double itemHeight;

  /// Spacing between items
  final double spacing;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        return SkeletonLoader.card(height: itemHeight);
      },
    );
  }
}

/// Device card skeleton
///
/// Skeleton loader for device status cards
class DeviceCardSkeleton extends StatelessWidget {
  const DeviceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader.circle(size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader.text(width: 120, height: 20),
                      const SizedBox(height: 8),
                      SkeletonLoader.text(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonLoader.text(height: 12),
            const SizedBox(height: 8),
            SkeletonLoader.text(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Event list item skeleton
///
/// Skeleton loader for event list items
class EventListItemSkeleton extends StatelessWidget {
  const EventListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SkeletonLoader.circle(size: 40),
      title: SkeletonLoader.text(width: 150, height: 16),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          SkeletonLoader.text(width: 200, height: 12),
          const SizedBox(height: 4),
          SkeletonLoader.text(width: 100, height: 10),
        ],
      ),
    );
  }
}
