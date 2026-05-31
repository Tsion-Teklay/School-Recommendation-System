import 'package:flutter/material.dart';  
import 'package:fl_chart/fl_chart.dart';  
import '../data/school_dtos.dart';  
  
class SchoolAnalyticsSection extends StatelessWidget {  
  final School school;  
  final Map<int, int> ratingDistribution;  
  
  const SchoolAnalyticsSection({  
    super.key,  
    required this.school,  
    required this.ratingDistribution,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    final passingRate = (school.passingRate ?? 0).toDouble();  
final examScore = (school.nationalExamScore ?? 0).toDouble(); 
  
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('School Performance', style: theme.textTheme.titleLarge),  
            const SizedBox(height: 16),  
              
            // Pie charts row  
            Row(  
              children: [  
                Expanded(  
                  child: _PieChartCard(  
                    title: 'Passing Rate',  
                    value: passingRate,  
                    subtitle: '${passingRate.toStringAsFixed(0)}% of students pass yearly',  
                    color: theme.colorScheme.primary,  
                  ),  
                ),  
                const SizedBox(width: 12),  
                Expanded(  
                  child: _PieChartCard(  
                    title: 'National Exam Score',  
                    value: examScore,  
                    subtitle: 'Average exam score: ${examScore.toStringAsFixed(0)}%',  
                    color: theme.colorScheme.tertiary,  
                  ),  
                ),  
              ],  
            ),  
              
            const SizedBox(height: 24),  
              
            // Rating distribution bar chart  
            Text('Rating Distribution', style: theme.textTheme.titleMedium),  
            const SizedBox(height: 12),  
            SizedBox(  
              height: 150,  
              child: BarChart(  
                BarChartData(  
                  alignment: BarChartAlignment.spaceAround,  
                  maxY: ratingDistribution.values.isEmpty   
                      ? 5   
                      : ratingDistribution.values.reduce((a, b) => a > b ? a : b).toDouble(),  
                  barGroups: List.generate(5, (index) {  
                    final rating = index + 1;  
                    final count = ratingDistribution[rating] ?? 0;  
                    return BarChartGroupData(  
                      x: index,  
                      barRods: [  
                        BarChartRodData(  
                          toY: count.toDouble(),  
                          color: theme.colorScheme.primary,  
                          width: 20,  
                          borderRadius: BorderRadius.circular(4),  
                        ),  
                      ],  
                    );  
                  }),  
                  titlesData: FlTitlesData(  
                    bottomTitles: AxisTitles(  
                      sideTitles: SideTitles(  
                        showTitles: true,  
                        getTitlesWidget: (value, meta) {  
                          return Text('${value.toInt() + 1}★');  
                        },  
                      ),  
                    ),  
                    leftTitles: AxisTitles(  
                      sideTitles: SideTitles(showTitles: false),  
                    ),  
                    topTitles: AxisTitles(  
                      sideTitles: SideTitles(showTitles: false),  
                    ),  
                    rightTitles: AxisTitles(  
                      sideTitles: SideTitles(showTitles: false),  
                    ),  
                  ),  
                  borderData: FlBorderData(show: false),  
                  gridData: FlGridData(show: false),  
                ),  
              ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}  
  
class _PieChartCard extends StatelessWidget {  
  final String title;  
  final double value;  
  final String subtitle;  
  final Color color;  
  
  const _PieChartCard({  
    required this.title,  
    required this.value,  
    required this.subtitle,  
    required this.color,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    return Column(  
      children: [  
        Text(title, style: theme.textTheme.titleMedium),  
        const SizedBox(height: 8),  
        SizedBox(  
          height: 140,  
          child: PieChart(  
            PieChartData(  
              sectionsSpace: 0,  
              centerSpaceRadius: 30,  
              sections: [  
                PieChartSectionData(  
                  value: value,  
                  color: color,  
                  radius: 40,  
                  showTitle: false,  
                ),  
                PieChartSectionData(  
                  value: 100 - value,  
                  color: theme.colorScheme.surfaceContainerHighest,  
                  radius: 40,  
                  showTitle: false,  
                ),  
              ],  
            ),  
          ),  
        ),  
        const SizedBox(height: 12),  
        Text(  
          subtitle,  
          style: theme.textTheme.bodySmall,  
          textAlign: TextAlign.center,  
        ),  
      ],  
    );  
  }  
}