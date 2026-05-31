import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Modern card with subtle gradient, enhanced shadows, and rounded corners
/// Designed to replace basic Card widgets throughout the app
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;
  final bool bordered;
  final Color? backgroundColor;
  final double? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevated = true,
    this.bordered = true,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? 20.0;

    Widget cardChild = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: backgroundColor == null 
            ? AppColors.surfaceGradient 
            : null,
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: bordered
            ? Border.all(
                color: AppColors.outline,
                width: 1,
              )
            : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardChild = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          child: cardChild,
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: cardChild,
    );
  }
}

/// Elevated card with stronger shadow for emphasis
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const ElevatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      elevated: true,
      bordered: true,
      backgroundColor: backgroundColor,
      borderRadius: 24,
      child: child,
    );
  }
}

/// Subtle card with minimal styling for content-heavy sections
class SubtleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const SubtleCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      elevated: false,
      bordered: true,
      backgroundColor: backgroundColor ?? AppColors.surfaceVariant,
      borderRadius: 16,
      child: child,
    );
  }
}

/// Action card with accent border for primary actions
class ActionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;

  const ActionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccentColor = accentColor ?? AppColors.accent;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveAccentColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveAccentColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Stat card for displaying metrics and key numbers
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppColors.primary;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      elevated: true,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Info card with icon for announcements and notifications
class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      elevated: true,
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  effectiveIconColor.withOpacity(0.15),
                  effectiveIconColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}