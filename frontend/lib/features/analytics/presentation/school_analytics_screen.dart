import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import '../../../shared/widgets/responsive_shell.dart';  
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
                          _MetricCard(  
  title: 'Achievement Score',  
  value: _analytics!.achievementScore.toStringAsFixed(0),  
  icon: Icons.emoji_events,  
  color: Colors.amber,  
),  
const SizedBox(height: 12),  
_MetricCard(  
  title: 'Gender Balance Index',  
  value: _analytics!.genderBalanceIndex.toStringAsFixed(2),  
  icon: Icons.balance,  
  color: Colors.blue,  
),  
const SizedBox(height: 12),  
_MetricCard(  
  title: 'Year-over-Year Growth',  
  value: '${_analytics!.yearOverYearGrowth.toStringAsFixed(1)}%',  
  icon: Icons.trending_up,  
  color: Colors.green,  
),  
const SizedBox(height: 12),  
_MetricCard(  
  title: 'Percentile Ranking',  
  value: '${_analytics!.percentileRanking.toStringAsFixed(0)}%',  
  icon: Icons.percent,  
  color: Colors.purple,  
),  
const SizedBox(height: 12),  
_MetricCard(  
  title: 'Parent Engagement Score',  
  value: _analytics!.parentEngagementScore.toStringAsFixed(0),  
  icon: Icons.people,  
  color: Colors.orange,  
),  
const SizedBox(height: 12),  
_MetricCard(  
  title: 'Community Trust Score',  
  value: _analytics!.communityTrustScore.toStringAsFixed(0),  
  icon: Icons.verified,  
  color: Colors.teal,  
),
                          const SizedBox(height: 24),  
                          Text('Historical Demographics', style: theme.textTheme.titleLarge),  
const SizedBox(height: 12),  
..._analytics!.demographics.map((d) => Card(  
  child: ListTile(  
    title: Text('Year ${d.academicYear}'),  
    subtitle: Text(  
      'Students: ${d.totalStudents} | Passing: ${d.passingRate}% | Exam: ${d.nationalExamScore}'  
    ),  
  ),  
)), 
                          const SizedBox(height: 24),  
                          Text('Verified Achievements', style: theme.textTheme.titleLarge),  
                          const SizedBox(height: 12),  
                          ..._analytics!.achievements.map((a) => Card(  
                            child: ListTile(  
                              title: Text(a.title),  
                              subtitle: Text('${a.tier} - ${a.year}'),  
                              trailing: Text('${a.score} pts'),  
                            ),  
                          )),  
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