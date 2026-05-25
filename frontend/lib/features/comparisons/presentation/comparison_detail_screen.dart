import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../../schools/data/school_dtos.dart';
import '../data/comparison_dtos.dart';
import '../data/comparison_repository.dart';

/// `/compare/:id` — side-by-side view. Rows = metric, columns = schools.
/// Loaded on-demand instead of plucking out of the list state, so a deep
/// link / page reload still works.
class ComparisonDetailScreen extends ConsumerStatefulWidget {
  final int comparisonId;
  const ComparisonDetailScreen({super.key, required this.comparisonId});

  @override
  ConsumerState<ComparisonDetailScreen> createState() =>
      _ComparisonDetailScreenState();
}

class _ComparisonDetailScreenState
    extends ConsumerState<ComparisonDetailScreen> {
  late Future<Comparison> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(comparisonRepositoryProvider)
        .getById(widget.comparisonId);
  }

  void _reload() {
    setState(() {
      _future = ref
          .read(comparisonRepositoryProvider)
          .getById(widget.comparisonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'Comparison',
      leading: BackButton(onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/compare');
        }
      }),
      child: FutureBuilder<Comparison>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            final err = snap.error;
            return _ErrorRow(
              message: err is ApiException ? err.message : err.toString(),
              onRetry: _reload,
            );
          }
          final c = snap.data!;
          return _ComparisonTable(comparison: c);
        },
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final Comparison comparison;
  const _ComparisonTable({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schools = comparison.schools;
    final metrics = comparison.metrics.isNotEmpty
        ? comparison.metrics
        : const ['curriculum', 'tuitionFee', 'rating', 'facilities', 'schoolLevel', 'schoolType', 'passingRate', 'nationalExamScore'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with school names
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'School Comparison',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                schools.map((s) => s.schoolName).join(' vs '),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Card-based side-by-side comparison
        Card(
          elevation: 2,
          child: Column(
            children: [
              // Header row with school names
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Metric label column
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Metric',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // School name columns
                    ...schools.map((school) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              school.schoolName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getVerificationColor(school.verificationStatus).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                school.verificationStatus.label(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getVerificationColor(school.verificationStatus),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Metric rows
              ...metrics.asMap().entries.map((entry) => _MetricRow(
                label: _label(entry.value),
                values: schools.map((s) => _value(s, entry.value)).toList(),
                theme: theme,
                index: entry.key,
              )),

              // Verification status row
              _MetricRow(
                label: 'Verification',
                values: schools.map((s) => s.verificationStatus.label()).toList(),
                theme: theme,
                index: metrics.length,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getVerificationColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.rejected:
      case VerificationStatus.revoked:
        return Colors.red;
    }
  }
}

String _label(String metric) {
  switch (metric) {
    case 'curriculum':
      return 'Curriculum';
    case 'tuitionFee':
      return 'Tuition fee';
    case 'rating':
      return 'Rating';
    case 'facilities':
      return 'Facilities';
    case 'schoolLevel':
      return 'School Level';
    case 'schoolType':
      return 'School Type';
    case 'passingRate':
      return 'Passing Rate';
    case 'nationalExamScore':
      return 'National Exam Score';
    case 'distance':
      return 'Distance';
    case 'totalStudents':
      return 'Total Students';
    case 'genderBalance':
      return 'Gender Balance';
    case 'achievementScore':
      return 'Achievement Score';
    default:
      return metric;
  }
}

String _value(School s, String metric) {
  switch (metric) {
    case 'curriculum':
      return s.curriculum.label();
    case 'tuitionFee':
      return s.tuitionFee?.toString() ?? '—';
    case 'rating':
      if ((s.rating ?? 0) == 0) return '—';
      return '${(s.rating ?? 0).toStringAsFixed(1)} '
          '(${s.reviewCount ?? 0})';
    case 'facilities':
      final f = s.facilities;
      if (f == null || f.trim().isEmpty) return '—';
      return f.length > 120 ? '${f.substring(0, 117)}…' : f;
    case 'distance':
      return s.distanceKm == null
          ? '—'
          : '${s.distanceKm!.toStringAsFixed(1)} km';
    case 'schoolLevel':
      return s.schoolLevel?.label() ?? '—';
    case 'schoolType':
      return s.schoolType?.label() ?? '—';
    case 'passingRate':
      return s.passingRate != null ? '${s.passingRate}%' : '—';
    case 'nationalExamScore':
      return s.nationalExamScore != null ? '${s.nationalExamScore}%' : '—';
    case 'totalStudents':
      return s.totalStudents != null ? '${s.totalStudents}' : '—';
    case 'genderBalance':
      if (s.genderBalance == null) return '—';
      final balance = s.genderBalance!;
      if (balance == 0) return 'Not balanced';
      if (balance >= 0.8) return 'Well balanced';
      if (balance >= 0.5) return 'Moderately balanced';
      return 'Poorly balanced';
    case 'achievementScore':
      return s.achievementScore != null ? '${s.achievementScore}' : '—';
    default:
      return '—';
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final ThemeData theme;
  final int index;

  const _MetricRow({
    required this.label,
    required this.values,
    required this.theme,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isEven ? theme.colorScheme.surface : null,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Metric label
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Value columns
          ...values.map((value) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRow({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
