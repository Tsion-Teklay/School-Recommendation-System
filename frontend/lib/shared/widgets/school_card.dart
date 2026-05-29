import 'package:flutter/material.dart';

import '../../features/schools/data/school_dtos.dart';

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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(dense ? 12 : 16),
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
                        if (school.rating != null && school.rating! > 0) ...[
                          const SizedBox(width: 8),
                          _StarRating(rating: school.rating!.toDouble()),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school.subCity != null
                          ? '${school.subCity} - ${school.woreda ?? 'N/A'}'
                          : 'No location info',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.school_outlined,
                          label: school.curriculum.label(),
                        ),
                        _Chip(
                          icon: Icons.payments_outlined,
                          label: _formatFee(school.tuitionFee),
                        ),
                        if ((school.rating ?? 0) > 0)
                          _Chip(
                            icon: Icons.star_outline,
                            label:
                                '${(school.rating ?? 0).toStringAsFixed(1)} (${school.reviewCount ?? 0})',
                          ),
                        if (school.verificationStatus ==
                            VerificationStatus.verified)
                          const _Chip(
                            icon: Icons.verified_outlined,
                            label: 'Verified',
                            highlighted: true,
                          ),
                        if (school.distanceKm != null)
                          _Chip(
                            icon: Icons.place_outlined,
                            label:
                                '${school.distanceKm!.toStringAsFixed(1)} km',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  const _Chip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlighted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = highlighted
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            size: 16,
            color: theme.colorScheme.primary,
          );
        } else if (index < rating && rating % 1 >= 0.5) {
          return Icon(
            Icons.star_half,
            size: 16,
            color: theme.colorScheme.primary,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          );
        }
      }),
    );
  }
}
