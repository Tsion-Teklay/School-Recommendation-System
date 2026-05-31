import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/design_system.dart';
import '../../features/schools/data/school_dtos.dart';
import 'custom_components.dart';

/// Re-usable card shown in browse list, recommendations, and comparison cart.
/// Keeps formatting consistent so a future redesign only edits one file.
class SchoolCard extends StatelessWidget {
  final School school;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool dense;

  const SchoolCard({
    super.key,
    required this.school,
    this.onTap,
    this.trailing,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.lgRadius,
        child: Padding(
          padding: EdgeInsets.all(dense ? AppSpacing.md : AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            school.schoolName,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        _StarRating(rating: school.rating?.toDouble() ?? 0),
                      ],
                    ),
                    SpacingHelper.xs,
                    Text(
                      school.subCity != null
                          ? '${school.subCity} - ${school.woreda ?? 'N/A'}'
                          : 'No location info',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SpacingHelper.sm,
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppBadge(
                          icon: Icons.school_outlined,
                          label: school.curriculum.label(),
                          small: true,
                        ),
                        AppBadge(
                          icon: Icons.payments_outlined,
                          label: _formatFee(school.tuitionFee),
                          small: true,
                        ),
                        if ((school.rating ?? 0) > 0)
                          AppBadge(
                            icon: Icons.star_outline,
                            label:
                                '${(school.rating ?? 0).toStringAsFixed(1)} (${school.reviewCount ?? 0})',
                            small: true,
                          ),
                        if (school.verificationStatus ==
                            VerificationStatus.verified)
                          AppBadge(
                            icon: Icons.verified_outlined,
                            label: 'Verified',
                            color: AppColors.success,
                            small: true,
                          ),
                        if (school.distanceKm != null)
                          AppBadge(
                            icon: Icons.place_outlined,
                            label:
                                '${school.distanceKm!.toStringAsFixed(1)} km',
                            small: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatFee(num? fee) {
  if (fee == null) return 'Not specified';
  if (fee >= 1000) {
    final k = fee / 1000;
    final str = k % 1 == 0 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
    return '$str k';
  }
  return fee.toStringAsFixed(0);
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            size: 16,
            color: AppColors.primary,
          );
        } else if (index < rating && rating % 1 >= 0.5) {
          return Icon(
            Icons.star_half,
            size: 16,
            color: AppColors.primary,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: 16,
            color: AppColors.textSecondary,
          );
        }
      }),
    );
  }
}
