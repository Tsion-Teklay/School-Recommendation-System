import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Comprehensive typography system for Fidel Guide
/// Provides consistent text styling across the application
class AppTypography {
  AppTypography._();

  // Font family
  static const String fontFamily = 'Plus Jakarta Sans';

  // ============================================
  // HEADLINE STYLES - For major headings
  // ============================================

  /// Display style - Largest text, used for hero sections
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.textPrimary,
      );

  // ============================================
  // HEADLINE STYLES - For page headings
  // ============================================

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.29,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.33,
        color: AppColors.textPrimary,
      );

  // ============================================
  // TITLE STYLES - For section headings
  // ============================================

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.27,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  // ============================================
  // BODY STYLES - For main content
  // ============================================

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  // ============================================
  // LABEL STYLES - For buttons, tags, captions
  // ============================================

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.29,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  // ============================================
  // SPECIALIZED STYLES
  // ============================================

  /// For emphasis within body text
  static TextStyle get bodyLargeEmphasized => bodyLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMediumEmphasized => bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// For button text
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.2,
        color: AppColors.textInverse,
      );

  /// For card titles
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  /// For card subtitles
  static TextStyle get cardSubtitle => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// For navigation items
  static TextStyle get navLabel => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.textSecondary,
      );

  /// For error messages
  static TextStyle get error => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.4,
        color: AppColors.error,
      );

  /// For success messages
  static TextStyle get success => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.4,
        color: AppColors.success,
      );

  /// For overline/caption text
  static TextStyle get overline => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: AppColors.textTertiary,
      );

  // ============================================
  // COLOR VARIANTS
  // ============================================

  /// Create text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Create primary color text style
  static TextStyle primary(TextStyle style) {
    return withColor(style, AppColors.primary);
  }

  /// Create accent color text style
  static TextStyle accent(TextStyle style) {
    return withColor(style, AppColors.accent);
  }

  /// Create secondary color text style
  static TextStyle secondary(TextStyle style) {
    return withColor(style, AppColors.secondary);
  }

  // ============================================
  // THEME INTEGRATION
  // ============================================

  /// Convert to Material TextTheme
  static TextTheme toTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}

/// Pre-defined text style combinations for common UI patterns
class TextStyles {
  TextStyles._();

  /// Hero section heading
  static TextStyle get heroHeading => AppTypography.displayLarge;

  /// Page heading with subtitle
  static TextStyle get pageHeading => AppTypography.headlineLarge;
  static TextStyle get pageSubheading => AppTypography.bodyMedium;

  /// Card content
  static TextStyle get cardTitle => AppTypography.cardTitle;
  static TextStyle get cardSubtitle => AppTypography.cardSubtitle;

  /// Button text
  static TextStyle get button => AppTypography.button;

  /// Form labels
  static TextStyle get formLabel => AppTypography.labelMedium;
  static TextStyle get formHint => AppTypography.bodySmall;

  /// Status text
  static TextStyle get status => AppTypography.labelSmall;
  static TextStyle get statusEmphasized => AppTypography.labelMedium;

  /// Navigation
  static TextStyle get navActive => AppTypography.navLabel.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      );
  static TextStyle get navInactive => AppTypography.navLabel;
}