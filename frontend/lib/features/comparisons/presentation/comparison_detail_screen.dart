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
    final rows = _buildRows(comparison);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparison #${comparison.id} · ${schools.length} schools',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 56,
            columnSpacing: 24,
            columns: [
              const DataColumn(label: Text('Metric')),
              ...schools.map(
                (s) => DataColumn(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      s.schoolName,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
            rows: rows
                .map((row) => DataRow(cells: [
                      DataCell(Text(row.label,
                          style: theme.textTheme.labelMedium)),
                      ...row.values.map((v) => DataCell(Text(v))),
                    ]))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<_Row> _buildRows(Comparison c) {
    final metrics = c.metrics.isNotEmpty
        ? c.metrics
        : const ['curriculum', 'tuitionFee', 'rating', 'facilities', 'schoolLevel', 'schoolType', 'passingRate', 'nationalExamScore'];
    final rows = <_Row>[];
    for (final metric in metrics) {
      rows.add(_Row(
        label: _label(metric),
        values: c.schools.map((s) => _value(s, metric)).toList(),
      ));
    }
    rows.add(_Row(
      label: 'Verification',
      values: c.schools.map((s) => s.verificationStatus.label()).toList(),
    ));
    return rows;
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
      default:
        return metric;
    }
  }

  String _value(School s, String metric) {  
  switch (metric) {  
    case 'curriculum':  
      return s.curriculum.label();  
    case 'tuitionFee':  
      return s.tuitionFee.toString();  
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
    default:  
      return '—';  
  }  
}
}

@immutable
class _Row {
  final String label;
  final List<String> values;
  const _Row({required this.label, required this.values});
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
