/// Responsive navigation scaffold
library;

import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Navigation destination
class NavDestination {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;

  const NavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.route,
  });
}

/// Responsive navigation scaffold
///
/// Adapts navigation UI based on screen size:
/// - Mobile: Bottom navigation bar
/// - Tablet/Desktop: Navigation rail (side)
class ResponsiveNavigationScaffold extends StatelessWidget {
  final Widget body;
  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const ResponsiveNavigationScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return _buildMobileLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  /// Mobile layout with bottom navigation
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map(
              (dest) => NavigationDestination(
                icon: Icon(dest.icon),
                selectedIcon: dest.selectedIcon != null
                    ? Icon(dest.selectedIcon)
                    : null,
                label: dest.label,
              ),
            )
            .toList(),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  /// Desktop layout with navigation rail
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: floatingActionButton != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: floatingActionButton,
                  )
                : null,
            destinations: destinations
                .map(
                  (dest) => NavigationRailDestination(
                    icon: Icon(dest.icon),
                    selectedIcon: dest.selectedIcon != null
                        ? Icon(dest.selectedIcon)
                        : null,
                    label: Text(dest.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// App navigation destinations
class AppDestinations {
  static const dashboard = NavDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: '/dashboard',
  );

  static const events = NavDestination(
    label: 'Events',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    route: '/events',
  );

  static const settings = NavDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/settings',
  );

  static const List<NavDestination> all = [dashboard, events, settings];

  static int indexOfRoute(String route) {
    return all.indexWhere((dest) => dest.route == route);
  }

  static NavDestination destinationForRoute(String route) {
    return all.firstWhere(
      (dest) => dest.route == route,
      orElse: () => dashboard,
    );
  }
}
