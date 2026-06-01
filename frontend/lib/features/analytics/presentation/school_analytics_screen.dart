import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../core/theme.dart';
import '../../auth/data/auth_repository.dart' show ApiException;
import '../data/analytics_repository.dart';
import '../data/analytics_dtos.dart';

class SchoolAnalyticsScreen extends ConsumerStatefulWidget {
  final int schoolId;
  const SchoolAnalyticsScreen({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolAnalyticsScreen> createState() => _SchoolAnalyticsScreenState();
}

class _SchoolAnalyticsScreenState extends ConsumerState<SchoolAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  SchoolAnalytics? _analytics;

  String? _getGenderBreakdown() {
    if (_analytics == null || _analytics!.demographics.isEmpty) return null;
    final latest = _analytics!.demographics.first;
    if (latest.totalStudents == 0) return null;

    final girlsPercent = ((latest.girlsCount / latest.totalStudents) * 100).round();
    final boysPercent = ((latest.boysCount / latest.totalStudents) * 100).round();
    return '$girlsPercent% Girls • $boysPercent% Boys';
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'GOLD':
        return Colors.amber;
      case 'SILVER':
        return Colors.grey;
      case 'BRONZE':
        return const Color(0xFFCD7F32);
      default:
        return Colors.amber;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(analyticsRepositoryProvider).getSchoolAnalytics(widget.schoolId);
      setState(() => _analytics = data);
    } on ApiException catch (e) {
      String errorMessage = e.message;
      if (e.statusCode == 401) {
        errorMessage = 'You must be logged in to view analytics';
      } else if (e.statusCode == 403) {
        errorMessage = 'You do not have permission to view these analytics';
      } else if (e.code == 'VALIDATION_ERROR' && e.details != null) {
        final validationErrors = e.details!.map((d) => '${d['path']}: ${d['message']}').join(', ');
        errorMessage = 'Validation error: $validationErrors';
      } else if (e.code == 'VALIDATION_ERROR') {
        errorMessage = 'Validation error: ${e.message}';
      }
      setState(() => _error = errorMessage);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveShell(
      title: 'School Analytics',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
                )
              : _analytics == null
                  ? const Center(child: Text('No analytics data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive grid: 3 columns on desktop, 2 on tablet, 1 on mobile
                              int crossAxisCount = 3;
                              if (constraints.maxWidth < 900) crossAxisCount = 2;
                              if (constraints.maxWidth < 600) crossAxisCount = 1;

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.2,
                                children: [
                                  _GridMetricCard(
                                    title: 'Achievement Score',
                                    value: _analytics!.achievementScore.toStringAsFixed(0),
                                    icon: Icons.emoji_events,
                                    color: AppColors.primaryLight,
                                  ),
                                  if (_getGenderBreakdown() != null)
                                    _GridMetricCard(
                                      title: 'Gender Distribution',
                                      value: _getGenderBreakdown()!,
                                      icon: Icons.people,
                                      color: Colors.blue,
                                    ),
                                  _GridMetricCard(
                                    title: 'Year-over-Year Growth',
                                    value: '${_analytics!.yearOverYearGrowth.toStringAsFixed(1)}%',
                                    icon: Icons.trending_up,
                                    color: Colors.green,
                                  ),
                                  _GridMetricCard(
                                    title: 'Percentile Ranking',
                                    value: '${_analytics!.percentileRanking.toStringAsFixed(0)}%',
                                    icon: Icons.percent,
                                    color: Colors.purple,
                                  ),
                                  _GridMetricCard(
                                    title: 'Parent Engagement Score',
                                    value: _analytics!.parentEngagementScore.toStringAsFixed(0),
                                    icon: Icons.people,
                                    color: Colors.orange,
                                  ),
                                  _GridMetricCard(
                                    title: 'Community Trust Score',
                                    value: _analytics!.communityTrustScore.toStringAsFixed(0),
                                    icon: Icons.verified,
                                    color: Colors.teal,
                                  ),
                                  _GridMetricCard(
                                    title: 'Staff Quality Score',
                                    value: '${(_analytics!.staffQualityScore * 100).toStringAsFixed(0)}%',
                                    icon: Icons.school,
                                    color: Colors.indigo,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Text('Historical Demographics', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ..._analytics!.demographics.map((d) => Card(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Academic Year ${d.academicYear}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AnalyticsStatCard(
                                          icon: Icons.people,
                                          label: 'Total Students',
                                          value: d.totalStudents.toString(),
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AnalyticsStatCard(
                                          icon: Icons.trending_up,
                                          label: 'Passing Rate',
                                          value: '${d.passingRate}%',
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AnalyticsStatCard(
                                          icon: Icons.school,
                                          label: 'National Exam',
                                          value: d.nationalExamScore.toString(),
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 24),
                          Text('Verified Achievements', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          if (_analytics!.achievements.isEmpty)
                            Card(
                              color: theme.colorScheme.primary.withOpacity(0.03),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No achievements yet', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          else
                            ..._analytics!.achievements.map((a) {
                              final tierColor = _getTierColor(a.tier ?? 'GOLD');
                              return Column(
                                children: [
                                  Card(
                                    color: theme.colorScheme.primary.withOpacity(0.03),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: tierColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.emoji_events,
                                              color: tierColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  a.title,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${a.tier} • ${a.year}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${a.score} pts',
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _GridMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.primary.withOpacity(0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AnalyticsStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}