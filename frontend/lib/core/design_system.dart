/// Design System for Fidel Guide
/// Provides consistent spacing, sizing, and layout guidelines
/// based on a 4px base unit for visual rhythm

import 'package:flutter/material.dart';

/// Base spacing unit (4px) - the foundation of our spacing scale
const double _baseUnit = 4.0;

class AppSpacing {
  AppSpacing._();

  // Spacing scale based on 4px base unit
  static const double xs = _baseUnit * 1; // 4px
  static const double sm = _baseUnit * 2; // 8px
  static const double md = _baseUnit * 3; // 12px
  static const double lg = _baseUnit * 4; // 16px
  static const double xl = _baseUnit * 5; // 20px
  static const double xxl = _baseUnit * 6; // 24px
  static const double xxxl = _baseUnit * 8; // 32px
  static const double huge = _baseUnit * 10; // 40px
  static const double massive = _baseUnit * 12; // 48px

  // Common spacing combinations
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double sectionSpacing = xxl;
  static const double elementSpacing = md;
  static const double tightSpacing = sm;
  static const double iconTextSpacing = sm;
  static const double listSpacing = md;

  // Specific component spacing
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(lg);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);
}

class AppBorderRadius {
  AppBorderRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double round = 999.0;

  static BorderRadius smRadius = BorderRadius.circular(sm);
  static BorderRadius mdRadius = BorderRadius.circular(md);
  static BorderRadius lgRadius = BorderRadius.circular(lg);
  static BorderRadius xlRadius = BorderRadius.circular(xl);
  static BorderRadius roundRadius = BorderRadius.circular(round);
}

class AppSizing {
  AppSizing._();

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Button heights
  static const double buttonSm = 36.0;
  static const double buttonMd = 44.0;
  static const double buttonLg = 52.0;

  // Input heights
  static const double inputSm = 36.0;
  static const double inputMd = 44.0;
  static const double inputLg = 52.0;

  // Card minimum heights
  static const double cardMinHeight = 80.0;
  static const double cardMinHeightLarge = 120.0;

  // Avatar sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;
}

class AppLayout {
  AppLayout._();

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Maximum content widths
  static const double maxContentWidth = 1200.0;
  static const double maxContentWidthNarrow = 800.0;
  static const double maxContentWidthWide = 1400.0;

  // Grid systems
  static const int gridColumnsMobile = 1;
  static const int gridColumnsTablet = 2;
  static const int gridColumnsDesktop = 3;
  static const double gridGap = AppSpacing.lg;
  static const double gridGapLarge = AppSpacing.xxl;

  // Safe area defaults
  static const double safeAreaDefault = 16.0;
  static const double safeAreaLarge = 24.0;
}

class AppDuration {
  AppDuration._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
}

class AppElevation {
  AppElevation._();

  static const double none = 0.0;
  static const double subtle = 1.0;
  static const double light = 2.0;
  static const double medium = 4.0;
  static const double heavy = 8.0;
  static const double heavyHeavier = 12.0;
}

/// Helper class for common spacing patterns
class SpacingHelper {
  SpacingHelper._();

  /// Vertical spacing with consistent visual rhythm
  static Widget verticalSpace(double height) => SizedBox(height: height);
  
  /// Horizontal spacing with consistent visual rhythm
  static Widget horizontalSpace(double width) => SizedBox(width: width);

  /// Common vertical spacings
  static Widget get xs => verticalSpace(AppSpacing.xs);
  static Widget get sm => verticalSpace(AppSpacing.sm);
  static Widget get md => verticalSpace(AppSpacing.md);
  static Widget get lg => verticalSpace(AppSpacing.lg);
  static Widget get xl => verticalSpace(AppSpacing.xl);
  static Widget get xxl => verticalSpace(AppSpacing.xxl);
  static Widget get xxxl => verticalSpace(AppSpacing.xxxl);

  /// Section divider with consistent spacing
  static Widget sectionDivider({
    Color? color,
    double thickness = 1.0,
    double height = AppSpacing.lg,
  }) {
    return Column(
      children: [
        verticalSpace(height / 2),
        Divider(
          color: color,
          thickness: thickness,
          height: height,
        ),
        verticalSpace(height / 2),
      ],
    );
  }

  /// Safe area padding with consistent values
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom,
    );
  }

  /// Screen padding with safe area consideration
  static EdgeInsets screenPaddingWithSafeArea(BuildContext context) {
    return EdgeInsets.only(
      left: AppSpacing.screenPadding,
      right: AppSpacing.screenPadding,
      bottom: MediaQuery.of(context).padding.bottom + AppSpacing.screenPadding,
    );
  }
}

/// Extension to add spacing methods to Widget
extension SpacingExtension on Widget {
  /// Add padding using spacing constants
  Widget padAll(double spacing) => Padding(
        padding: EdgeInsets.all(spacing),
        child: this,
      );

  Widget padSymmetric({double horizontal = 0, double vertical = 0}) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Widget padOnly({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
        ),
        child: this,
      );

  /// Add margin using spacing constants
  Widget marginAll(double spacing) => Container(
        margin: EdgeInsets.all(spacing),
        child: this,
      );

  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) => Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  /// Add consistent spacing below
  Widget spacedBelow(double spacing) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          this,
          SizedBox(height: spacing),
        ],
      );

  /// Add consistent spacing above
  Widget spacedAbove(double spacing) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: spacing),
          this,
        ],
      );
}