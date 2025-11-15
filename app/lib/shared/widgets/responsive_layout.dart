/// Responsive layout widgets
library;

/// Responsive layout components
///
/// Provides widgets that adapt to different screen sizes
/// using the responsive utilities from core/utils/responsive.dart.

import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Responsive container with max width
///
/// Constrains content to maximum width on large screens
/// while allowing full width on mobile.
class ResponsiveContainer extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// Optional background color
  final Color? color;

  /// Optional padding
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.maxContentWidth(context);
    final defaultPadding = Responsive.horizontalPadding(context);

    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: maxWidth),
        color: color,
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );
  }
}

/// Responsive grid layout
///
/// Creates a grid that adapts column count based on screen size.
class ResponsiveGridView extends StatelessWidget {
  /// List of items to display
  final List<Widget> children;

  /// Spacing between grid items
  final double? spacing;

  /// Aspect ratio of grid items
  final double childAspectRatio;

  /// Optional padding
  final EdgeInsetsGeometry? padding;

  /// Whether grid should be scrollable
  final bool shrinkWrap;

  /// Physics for scrolling
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    final gridSpacing = spacing ?? Responsive.spacing(context);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: gridSpacing,
      mainAxisSpacing: gridSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}

/// Responsive card with adaptive padding and elevation
class ResponsiveCard extends StatelessWidget {
  /// Card content
  final Widget child;

  /// Optional title
  final String? title;

  /// Optional subtitle
  final String? subtitle;

  /// Optional leading widget
  final Widget? leading;

  /// Optional trailing widget
  final Widget? trailing;

  /// Optional tap callback
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = Responsive.padding(context);

    final card = Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null || leading != null || trailing != null)
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              if (title != null || subtitle != null) const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );

    return card;
  }
}

/// Responsive two-column layout
///
/// Shows single column on mobile, two columns on tablet/desktop.
class ResponsiveTwoColumn extends StatelessWidget {
  /// Left column content
  final Widget left;

  /// Right column content
  final Widget right;

  /// Spacing between columns
  final double? spacing;

  /// Flex ratio for left column (default 1)
  final int leftFlex;

  /// Flex ratio for right column (default 1)
  final int rightFlex;

  const ResponsiveTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.spacing,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final columnSpacing = spacing ?? Responsive.spacing(context);

    if (Responsive.isMobile(context)) {
      // Stack vertically on mobile
      return Column(
        children: [
          left,
          SizedBox(height: columnSpacing),
          right,
        ],
      );
    }

    // Show side-by-side on tablet/desktop
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        SizedBox(width: columnSpacing),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}

/// Responsive list with adaptive item layout
///
/// Shows items in grid on large screens, list on mobile.
class ResponsiveList extends StatelessWidget {
  /// Number of items
  final int itemCount;

  /// Item builder
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Optional separator builder
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Optional padding
  final EdgeInsetsGeometry? padding;

  /// Whether list should be scrollable
  final bool shrinkWrap;

  /// Physics for scrolling
  final ScrollPhysics? physics;

  const ResponsiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      // Use list view on mobile
      if (separatorBuilder != null) {
        return ListView.separated(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          separatorBuilder: separatorBuilder!,
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
        );
      }
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
      );
    }

    // Use grid on tablet/desktop
    final columns = Responsive.gridColumns(context);
    final gridSpacing = Responsive.spacing(context);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: gridSpacing,
        childAspectRatio: 1.5,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }
}
