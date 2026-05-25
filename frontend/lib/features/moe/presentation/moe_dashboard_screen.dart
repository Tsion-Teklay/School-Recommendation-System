import 'dart:convert';  
import 'dart:html' as html; // For Web downloads 

import 'package:flutter/material.dart';  
import 'package:flutter/services.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
import 'package:fl_chart/fl_chart.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../analytics/data/analytics_dtos.dart';  
import '../../analytics/data/analytics_repository.dart';  
import '../../auth/data/auth_repository.dart';  
  
class MoeDashboardScreen extends ConsumerStatefulWidget {  
  const MoeDashboardScreen({super.key});  
  
  @override  
  ConsumerState<MoeDashboardScreen> createState() =>  
      _MoeDashboardScreenState();  
}  
  
class _MoeDashboardScreenState extends ConsumerState<MoeDashboardScreen> {  
  bool _loading = false;  
  String? _error;  
  Dashboard? _dashboard;  
  
  @override  
  void initState() {  
    super.initState();  
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());  
  }  
  
  Future<void> _load() async {  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      final d = await ref.read(analyticsRepositoryProvider).dashboard();  
      setState(() => _dashboard = d);  
    } on ApiException catch (e) {
      String errorMessage = e.message;
      if (e.statusCode == 401) {
        errorMessage = 'You must be logged in to view the dashboard';
      } else if (e.statusCode == 403) {
        errorMessage = 'You do not have permission to view the dashboard';
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
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _downloadCsv() async {  
  try {  
    setState(() => _loading = true);  
      
    // Fetch the raw CSV string from the repository  
    final csvData = await ref.read(analyticsRepositoryProvider).dashboardCsv();  
      
    // Create a data blob and trigger download  
    final bytes = utf8.encode(csvData);  
    final blob = html.Blob([bytes], 'text/csv');  
    final url = html.Url.createObjectUrlFromBlob(blob);  
      
    final anchor = html.AnchorElement(href: url)  
      ..setAttribute("download", "moe-dashboard-${DateTime.now().toIso8601String().split('T')[0]}.csv")  
      ..click();  
        
    html.Url.revokeObjectUrl(url);  
  
    if (!mounted) return;  
    ScaffoldMessenger.of(context).showSnackBar(  
      const SnackBar(content: Text('Download started successfully.')),  
    );  
  } on ApiException catch (e) {  
    if (!mounted) return;  
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));  
  } finally {  
    if (mounted) setState(() => _loading = false);  
  }  
}
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    final d = _dashboard;  
    return ResponsiveShell(  
      title: 'Ministry dashboard',  
      child: _loading && d == null  
          ? const Padding(  
              padding: EdgeInsets.symmetric(vertical: 48),  
              child: Center(child: CircularProgressIndicator()),  
            )  
          : _error != null  
              ? Card(  
                  color: theme.colorScheme.errorContainer,  
                  child: Padding(  
                    padding: const EdgeInsets.all(16),  
                    child: Text(_error!),  
                  ),  
                )  
              : d == null  
                  ? const SizedBox.shrink()  
                  : SingleChildScrollView(  
                      padding: const EdgeInsets.all(16),  
                      child: Column(  
                        crossAxisAlignment: CrossAxisAlignment.stretch,  
                        children: [  
                          Wrap(  
                            alignment: WrapAlignment.spaceBetween,  
                            spacing: 8,  
                            runSpacing: 8,  
                            crossAxisAlignment: WrapCrossAlignment.center,  
                            children: [  
                              Text('Overview',  
                                  style: theme.textTheme.headlineSmall),  
                              Wrap(  
                                spacing: 8,  
                                crossAxisAlignment: WrapCrossAlignment.center,  
                                children: [  
                                  IconButton(  
                                    tooltip: 'Refresh',  
                                    onPressed: _load,  
                                    icon: const Icon(Icons.refresh),  
                                  ),  
                                  FilledButton.icon(  
                                    onPressed: _downloadCsv, // Changed from _copyCsv  
                                    icon: const Icon(Icons.file_download), // Updated icon  
                                    label: const Text('Download CSV'), // Updated label  
                                  ), 
                                ],  
                              ),  
                            ],  
                          ),  
                          const SizedBox(height: 16),  
                          _KpiCard(  
                            label: 'Total Schools',  
                            value: d.summary.totalSchools,  
                          ),  
                          const SizedBox(height: 24),  
                          _UsersByRoleChart(data: d.usersByRole),  
                          const SizedBox(height: 24),  
                          _SchoolsByVerificationChart(data: d.schoolsByVerification),  
                          const SizedBox(height: 24),  
                          _SchoolsBySubcityChart(data: d.schoolsBySubcity),  
                          const SizedBox(height: 24),  
                          _TopSchoolsByRatingChart(schools: d.topSchools),  
                          const SizedBox(height: 24),  
                          _MostFollowedLeaderboard(schools: d.mostFollowed),  
                          const SizedBox(height: 24),  
                          _MoeRankingLeaderboard(schools: d.moeRanking),  
                        ],  
                      ),  
                    ),  
    );  
  }  
}  
  
// 1. KPI Card for Total Schools  
class _KpiCard extends StatelessWidget {  
  final String label;  
  final int value;  
  const _KpiCard({required this.label, required this.value});  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    return Card(  
      elevation: 4,  
      child: Padding(  
        padding: const EdgeInsets.all(24),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text(label, style: theme.textTheme.titleMedium?.copyWith(  
              color: theme.colorScheme.primary,  
            )),  
            const SizedBox(height: 12),  
            Text('$value',  
                style: theme.textTheme.displayLarge?.copyWith(  
                  fontWeight: FontWeight.bold,  
                  color: theme.colorScheme.onSurface,  
                )),  
          ],  
        ),  
      ),  
    );  
  }  
}  
  
// 2. Users by Role Bar Chart  
class _UsersByRoleChart extends StatelessWidget {  
  final Map<String, int> data;  
  const _UsersByRoleChart({required this.data});  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    if (data.isEmpty) {  
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No data')));  
    }  
      
    final entries = data.entries.toList();  
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);  
      
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('Users by Role', style: theme.textTheme.titleMedium),  
            const SizedBox(height: 16),  
            SizedBox(  
              height: 200,  
              child: BarChart(  
                BarChartData(  
                  alignment: BarChartAlignment.spaceAround,  
                  maxY: maxValue > 0 ? maxValue * 1.2 : 10,  
                  barTouchData: BarTouchData(enabled: true),  
                  titlesData: FlTitlesData(  
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  
                    bottomTitles: AxisTitles(  
                      sideTitles: SideTitles(  
                        showTitles: true,  
                        getTitlesWidget: (value, meta) {  
                          final index = value.toInt();  
                          if (index >= 0 && index < entries.length) {  
                            return Padding(  
                              padding: const EdgeInsets.only(top: 8),  
                              child: Text(  
                                entries[index].key,  
                                style: theme.textTheme.bodySmall,  
                              ),  
                            );  
                          }  
                          return const SizedBox();  
                        },  
                      ),  
                    ),  
                  ),  
                  borderData: FlBorderData(show: false),  
                  barGroups: entries.asMap().entries.map((entry) {  
                    return BarChartGroupData(  
                      x: entry.key,  
                      barRods: [  
                        BarChartRodData(  
                          toY: entry.value.value.toDouble(),  
                          color: theme.colorScheme.primary,  
                          width: 20,  
                          borderRadius: BorderRadius.circular(4),  
                        ),  
                      ],  
                    );  
                  }).toList(),  
                ),  
              ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}  
  
// 3. Schools by Verification Pie Chart  
class _SchoolsByVerificationChart extends StatelessWidget {  
  final Map<String, int> data;  
  const _SchoolsByVerificationChart({required this.data});  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    if (data.isEmpty) {  
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No data')));  
    }  
      
    final colorMap = {  
      'VERIFIED': Colors.green,  
      'PENDING': Colors.orange,  
      'REJECTED': Colors.red,  
    };  
      
    final entries = data.entries.toList();  
    final total = entries.fold(0, (sum, e) => sum + e.value);  
      
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('Schools by Verification', style: theme.textTheme.titleMedium),  
            const SizedBox(height: 16),  
            SizedBox(  
              height: 200,  
              child: PieChart(  
                PieChartData(  
                  sectionsSpace: 2,  
                  centerSpaceRadius: 40,  
                  sections: entries.map((e) {  
                    final value = e.value;  
                    final percentage = total > 0 ? value / total : 0;  
                    return PieChartSectionData(  
                      value: value.toDouble(),  
                      title: '${(percentage * 100).toStringAsFixed(1)}%',  
                      color: colorMap[e.key] ?? Colors.grey,  
                      radius: 50,  
                      titleStyle: theme.textTheme.bodySmall?.copyWith(  
                        color: Colors.white,  
                        fontWeight: FontWeight.bold,  
                      ),  
                    );  
                  }).toList(),  
                ),  
              ),  
            ),  
            const SizedBox(height: 16),  
            Wrap(  
              spacing: 16,  
              children: entries.map((e) => Row(  
                mainAxisSize: MainAxisSize.min,  
                children: [  
                  Container(  
                    width: 12,  
                    height: 12,  
                    decoration: BoxDecoration(  
                      color: colorMap[e.key] ?? Colors.grey,  
                      shape: BoxShape.circle,  
                    ),  
                  ),  
                  const SizedBox(width: 8),  
                  Text('${e.key}: ${e.value}', style: theme.textTheme.bodySmall),  
                ],  
              )).toList(),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}  
  
// 4. Schools by Subcity Bar Chart
class _SchoolsBySubcityChart extends StatelessWidget {
  final Map<String, int> data;
  const _SchoolsBySubcityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No subcity data available')));
    }
      
    final entries = data.entries.toList();
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schools by Subcity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue > 0 ? maxValue * 1.2 : 10,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                entries[index].key,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: entries.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: theme.colorScheme.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Top Schools by Rating Horizontal Bar Chart  
class _TopSchoolsByRatingChart extends StatelessWidget {  
  final List<TopSchool> schools;  
  const _TopSchoolsByRatingChart({required this.schools});  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    if (schools.isEmpty) {  
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No schools yet.')));  
    }  
      
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('Top Schools by Rating', style: theme.textTheme.titleMedium),  
            const SizedBox(height: 16),  
            SizedBox(  
              height: schools.length * 60.0,  
              child: BarChart(  
                BarChartData(  
                  alignment: BarChartAlignment.spaceAround,  
                  minY: 0,  
                  maxY: 5,  
                  barTouchData: BarTouchData(enabled: true),  
                  titlesData: FlTitlesData(  
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),  
                    bottomTitles: AxisTitles(  
                      sideTitles: SideTitles(  
                        showTitles: true,  
                        getTitlesWidget: (value, meta) {  
                          final index = value.toInt();  
                          if (index >= 0 && index < schools.length) {  
                            return Padding(  
                              padding: const EdgeInsets.only(top: 8),  
                              child: Text(  
                                schools[index].schoolName,  
                                style: theme.textTheme.bodySmall,  
                                maxLines: 1,  
                                overflow: TextOverflow.ellipsis,  
                              ),  
                            );  
                          }  
                          return const SizedBox();  
                        },  
                      ),  
                    ),  
                  ),  
                  borderData: FlBorderData(show: false),  
                  barGroups: schools.asMap().entries.map((entry) {  
                    return BarChartGroupData(  
                      x: entry.key,  
                      barRods: [  
                        BarChartRodData(  
                          toY: entry.value.rating,  
                          color: theme.colorScheme.primary,  
                          width: 16,  
                          borderRadius: BorderRadius.circular(4),  
                        ),  
                      ],  
                    );  
                  }).toList(),  
                ),  
              ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}

// 6. Most Followed Schools Leaderboard with Mini Bars  
class _MostFollowedLeaderboard extends StatelessWidget {  
  final List<MostFollowed> schools;  
  const _MostFollowedLeaderboard({required this.schools});  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    if (schools.isEmpty) {  
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No followers yet.')));  
    }  
      
    final maxFollowers = schools.map((s) => s.followers).reduce((a, b) => a > b ? a : b);  
      
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('Most Followed Schools', style: theme.textTheme.titleMedium),  
            const SizedBox(height: 16),  
            ...schools.asMap().entries.map((entry) {  
              final index = entry.key;  
              final school = entry.value;  
              final percentage = maxFollowers > 0 ? school.followers / maxFollowers : 0;  
                
              return Padding(  
                padding: const EdgeInsets.only(bottom: 12),  
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.start,  
                  children: [  
                    Row(  
                      children: [  
                        Container(  
                          width: 24,  
                          height: 24,  
                          decoration: BoxDecoration(  
                            color: theme.colorScheme.primary,  
                            shape: BoxShape.circle,  
                          ),  
                          child: Center(  
                            child: Text(  
                              '${index + 1}',  
                              style: theme.textTheme.bodySmall?.copyWith(  
                                color: theme.colorScheme.onPrimary,  
                                fontWeight: FontWeight.bold,  
                              ),  
                            ),  
                          ),  
                        ),  
                        const SizedBox(width: 12),  
                        Expanded(  
                          child: Column(  
                            crossAxisAlignment: CrossAxisAlignment.start,  
                            children: [  
                              Text(  
                                school.schoolName ?? 'School #${school.schoolId}',  
                                style: theme.textTheme.bodyMedium?.copyWith(  
                                  fontWeight: FontWeight.w500,  
                                ),  
                              ),  
                              const SizedBox(height: 4),  
                              ClipRRect(  
                                borderRadius: BorderRadius.circular(4),  
                                child: LinearProgressIndicator(  
                                  value: percentage.toDouble(),  
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,  
                                  valueColor: AlwaysStoppedAnimation<Color>(  
                                    theme.colorScheme.primary,  
                                  ),  
                                  minHeight: 8,  
                                ),  
                              ),  
                            ],  
                          ),  
                        ),  
                        const SizedBox(width: 12),  
                        Text(  
                          '${school.followers}',  
                          style: theme.textTheme.bodyMedium?.copyWith(  
                            fontWeight: FontWeight.bold,  
                          ),  
                        ),  
                        const SizedBox(width: 8),  
                        IconButton(  
                          icon: const Icon(Icons.open_in_new, size: 20),  
                          onPressed: () => context.go('/schools/${school.schoolId}'),  
                        ),  
                      ],  
                    ),  
                  ],  
                ),  
              );  
            }).toList(),  
          ],  
        ),  
      ),  
    );  
  }  
}

// 7. MoE Ranking Leaderboard (Top 10)  
class _MoeRankingLeaderboard extends StatelessWidget {  
  final List<MoeRankedSchool> schools;  
  const _MoeRankingLeaderboard({required this.schools});  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    if (schools.isEmpty) {  
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No ranking data available.')));  
    }  
      
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('MoE School Ranking (Top 10)', style: theme.textTheme.titleMedium),  
            const SizedBox(height: 16),  
            ...schools.asMap().entries.map((entry) {  
              final index = entry.key;  
              final school = entry.value;  
                
              return ListTile(  
                contentPadding: EdgeInsets.zero,  
                leading: Container(  
                  width: 32,  
                  height: 32,  
                  decoration: BoxDecoration(  
                    color: index < 3   
                        ? theme.colorScheme.primary   
                        : theme.colorScheme.surfaceContainerHighest,  
                    shape: BoxShape.circle,  
                  ),  
                  child: Center(  
                    child: Text(  
                      '${index + 1}',  
                      style: theme.textTheme.bodyMedium?.copyWith(  
                        color: index < 3   
                            ? theme.colorScheme.onPrimary   
                            : theme.colorScheme.onSurface,  
                        fontWeight: FontWeight.bold,  
                      ),  
                    ),  
                  ),  
                ),  
                title: Text(school.schoolName),  
                subtitle: Text(  
  'Score: ${school.moeScore.toStringAsFixed(2)} · '  
  'Rating: ${school.rating.toStringAsFixed(1)} · '  
  '${school.verificationStatus}'  
  '${school.schoolLevel != null ? ' · Level: ${school.schoolLevel}' : ''}'  
  '${school.schoolType != null ? ' · Type: ${school.schoolType}' : ''}'  
  '${school.passingRate != null ? ' · Pass: ${school.passingRate}%' : ''}'  
  '${school.nationalExamScore != null ? ' · Exam: ${school.nationalExamScore}%' : ''}',  
),  
                trailing: IconButton(  
                  icon: const Icon(Icons.open_in_new),  
                  onPressed: () => context.go('/schools/${school.id}'),  
                ),  
              );  
            }).toList(),  
          ],  
        ),  
      ),  
    );  
  }  
}