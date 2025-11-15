/// Responsive Layout Utilities for Harvia MSGA
///
/// Provides breakpoints and utilities for mobile, tablet, and desktop layouts
library;

import 'package:flutter/material.dart';

/// Responsive breakpoints
class Responsive {
  Responsive._();

  /// Mobile breakpoint (< 600px)
  static const double mobileBreakpoint = 600;

  /// Tablet breakpoint (600px - 1024px)
  static const double tabletBreakpoint = 1024;

  /// Desktop breakpoint (> 1024px)
  static const double desktopBreakpoint = 1024;

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on screen size
  ///
  /// Example:
  /// ```dart
  /// final padding = Responsive.value(
  ///   context,
  ///   mobile: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get number of columns for grid layout
  static int gridColumns(BuildContext context, {int maxColumns = 4}) {
    if (isDesktop(context)) return maxColumns;
    if (isTablet(context)) return (maxColumns / 2).ceil();
    return 1;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.all(
      value<double>(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value<double>(
        context: context,
        mobile: 16.0,
        tablet: 32.0,
        desktop: 48.0,
      ),
    );
  }

  /// Get responsive vertical padding
  static EdgeInsets verticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      vertical: value<double>(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  /// Get responsive spacing
  static double spacing(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// Get maximum content width (for centered content on large screens)
  static double maxContentWidth(BuildContext context) {
    return value<double>(
      context: context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );
  }

  /// Get responsive font size multiplier
  static double fontSizeMultiplier(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );
  }
}

/// Responsive layout widget
///
/// Builds different layouts for mobile, tablet, and desktop
///
/// Example:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Responsive grid widget
///
/// Creates a grid with responsive column count
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.maxColumns = 4,
    this.spacing = 16.0,
    super.key,
  });

  final List<Widget> children;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context, maxColumns: maxColumns);

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      padding: Responsive.padding(context),
      children: children,
    );
  }
}

/// Centered content container with max width
///
/// Prevents content from stretching too wide on large screens
class CenteredContent extends StatelessWidget {
  const CenteredContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
