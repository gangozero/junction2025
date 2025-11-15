/// Layout and responsive design constants
library;

/// Layout constants for responsive design
class LayoutConstants {
  LayoutConstants._();

  // Breakpoints (dp/logical pixels)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Padding
  static const double paddingMobile = 16.0;
  static const double paddingTablet = 24.0;
  static const double paddingDesktop = 32.0;

  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Card dimensions
  static const double cardElevation = 4.0;
  static const double cardBorderRadius = 12.0;

  // Widget sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Button dimensions
  static const double buttonHeight = 48.0;
  static const double buttonMinWidth = 88.0;
  static const double buttonBorderRadius = 8.0;

  // Max widths for content
  static const double maxContentWidthMobile = 600;
  static const double maxContentWidthTablet = 900;
  static const double maxContentWidthDesktop = 1200;

  // Grid columns
  static const int gridColumnsMobile = 1;
  static const int gridColumnsTablet = 2;
  static const int gridColumnsDesktop = 3;
}
