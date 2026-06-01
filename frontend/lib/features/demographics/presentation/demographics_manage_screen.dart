import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/utils/message_helper.dart';
import '../data/demographics_repository.dart';
import '../data/demographics_dtos.dart';

class DemographicsManageScreen extends ConsumerStatefulWidget {
  final int schoolId;
  const DemographicsManageScreen({super.key, required this.schoolId});

  @override
  ConsumerState<DemographicsManageScreen> createState() => _DemographicsManageScreenState();
}

class _DemographicsManageScreenState extends ConsumerState<DemographicsManageScreen> {
  final _form = GlobalKey<FormState>();
  final _academicYear = TextEditingController(text: '2024');
  final _totalStudents = TextEditingController();
  final _girlsCount = TextEditingController();
  final _boysCount = TextEditingController();
  final _passingRate = TextEditingController();
  final _nationalExamScore = TextEditingController();

  bool _loading = false;
  List<SchoolDemographics> _demographics = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _academicYear.dispose();
    _totalStudents.dispose();
    _girlsCount.dispose();
    _boysCount.dispose();
    _passingRate.dispose();
    _nationalExamScore.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await ref.read(demographicsRepositoryProvider).getBySchool(widget.schoolId);
      // Sort by academic year in descending order (newest first)
      setState(() => _demographics = data..sort((a, b) => b.academicYear.compareTo(a.academicYear)));
    } catch (e) {
      // Don't show loading errors - it's normal to have no demographics initially
      print('Failed to load demographics: $e');
      setState(() => _demographics = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    // Cross-field validation: total students must equal girls + boys
    final totalStudents = int.parse(_totalStudents.text);
    final girlsCount = int.parse(_girlsCount.text);
    final boysCount = int.parse(_boysCount.text);

    if (totalStudents != girlsCount + boysCount) {
      final errorMessage = 'Total students ($totalStudents) must equal girls ($girlsCount) + boys ($boysCount). Current sum is ${girlsCount + boysCount}.';
      MessageHelper.showError(context, errorMessage);
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      await ref.read(demographicsRepositoryProvider).create(
        schoolId: widget.schoolId,
        academicYear: int.parse(_academicYear.text),
        totalStudents: totalStudents,
        girlsCount: girlsCount,
        boysCount: boysCount,
        passingRate: double.parse(_passingRate.text),
        nationalExamScore: double.parse(_nationalExamScore.text),
      );

      // Clear form fields
      _academicYear.clear();
      _totalStudents.clear();
      _girlsCount.clear();
      _boysCount.clear();
      _passingRate.clear();
      _nationalExamScore.clear();
      _academicYear.text = '2024'; // Reset to default

      if (mounted) MessageHelper.showSuccess(context, 'Demographics added successfully');

      // Reload demographics list
      await _load();
    } catch (e) {
      if (mounted) MessageHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'School Demographics',
      child: _loading && _demographics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Existing Demographics:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_demographics.isEmpty)
                    const Text('No demographics submitted yet', style: TextStyle(color: Colors.grey))
                  else
                    ..._demographics.map((d) => Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Academic Year ${d.academicYear}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.people,
                                    label: 'Total Students',
                                    value: d.totalStudents.toString(),
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.girl,
                                    label: 'Girls',
                                    value: d.girlsCount.toString(),
                                    color: Colors.pink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.boy,
                                    label: 'Boys',
                                    value: d.boysCount.toString(),
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.trending_up,
                                    label: 'Passing Rate',
                                    value: '${d.passingRate}%',
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
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
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text('Add New Demographics:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _academicYear,
                          decoration: const InputDecoration(labelText: 'Academic Year'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _totalStudents,
                          decoration: const InputDecoration(labelText: 'Total Students'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            final value = int.tryParse(v!);
                            if (value == null) return 'Please enter a valid number';
                            if (value < 0) return 'Total students cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _girlsCount,
                          decoration: const InputDecoration(labelText: 'Girls Count'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            final value = int.tryParse(v!);
                            if (value == null) return 'Please enter a valid number';
                            if (value < 0) return 'Girls count cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _boysCount,
                          decoration: const InputDecoration(labelText: 'Boys Count'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            final value = int.tryParse(v!);
                            if (value == null) return 'Please enter a valid number';
                            if (value < 0) return 'Boys count cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passingRate,
                          decoration: const InputDecoration(labelText: 'Passing Rate (%)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            final value = double.tryParse(v!);
                            if (value == null) return 'Please enter a valid number';
                            if (value < 0) return 'Passing rate cannot be negative';
                            if (value > 100) return 'Passing rate cannot exceed 100%';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nationalExamScore,
                          decoration: const InputDecoration(labelText: 'National Exam Score'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            final value = double.tryParse(v!);
                            if (value == null) return 'Please enter a valid number';
                            if (value < 0) return 'Exam score cannot be negative';
                            if (value > 600) return 'Exam score cannot exceed 600';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        LoadingButton(
                          loading: _loading,
                          onPressed: _submit,
                          child: const Text('Add Demographics'),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
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