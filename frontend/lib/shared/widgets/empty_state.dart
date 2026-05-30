import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/design_system.dart';
import '../../core/typography.dart';
import 'illustrations.dart';

/// Reusable empty state widget with custom illustrations
/// Replaces Material icons with branded illustrations for better visual appeal
class EmptyState extends StatelessWidget {
  final IllustrationType illustrationType;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? illustrationSize;

  const EmptyState({
    super.key,
    required this.illustrationType,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.illustrationSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.dialogPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIllustration(
              type: illustrationType,
              size: illustrationSize ?? AppSizing.iconXl * 2,
              color: AppColors.primary,
              showBackground: true,
            ),
            SpacingHelper.xxl,
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              SpacingHelper.sm,
              Text(
                description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SpacingHelper.xxl,
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.mdRadius,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state card for use in lists and grids
class EmptyStateCard extends StatelessWidget {
  final IllustrationType illustrationType;
  final String title;
  final String? description;

  const EmptyStateCard({
    super.key,
    required this.illustrationType,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.dialogPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.lgRadius,
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          AppIllustration(
            type: illustrationType,
            size: AppSizing.iconXl * 1.5,
            color: AppColors.primary,
            showBackground: true,
          ),
          SpacingHelper.lg,
          Text(
            title,
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            SpacingHelper.sm,
            Text(
              description!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}