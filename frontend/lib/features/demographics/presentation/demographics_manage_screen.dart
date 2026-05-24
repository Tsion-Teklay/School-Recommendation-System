import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../../shared/widgets/loading_button.dart';  
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
  String? _error;  
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
      _error = null;  
    });  
    try {  
      final data = await ref.read(demographicsRepositoryProvider).getBySchool(widget.schoolId);  
      setState(() => _demographics = data);  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _submit() async {  
  if (!_form.currentState!.validate()) return;  
  setState(() {  
    _loading = true;  
    _error = null;  
  });  
  try {  
    await ref.read(demographicsRepositoryProvider).create(  
      schoolId: widget.schoolId,  
      academicYear: int.parse(_academicYear.text),  
      totalStudents: int.parse(_totalStudents.text),  
      girlsCount: int.parse(_girlsCount.text),  
      boysCount: int.parse(_boysCount.text),  
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
      
    // Reload demographics list  
    await _load();  
      
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(  
      const SnackBar(content: Text('Demographics added successfully')),  
    );  
  } catch (e) {  
    setState(() => _error = e.toString());  
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
              child: Form(  
                key: _form,  
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.stretch,  
                  children: [  
                    if (_error != null) ...[  
                      Text(_error!, style: const TextStyle(color: Colors.red)),  
                      const SizedBox(height: 16),  
                    ],  
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
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _girlsCount,  
                      decoration: const InputDecoration(labelText: 'Girls Count'),  
                      keyboardType: TextInputType.number,  
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _boysCount,  
                      decoration: const InputDecoration(labelText: 'Boys Count'),  
                      keyboardType: TextInputType.number,  
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _passingRate,  
                      decoration: const InputDecoration(labelText: 'Passing Rate (%)'),  
                      keyboardType: TextInputType.number,  
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 12),  
                    TextFormField(  
                      controller: _nationalExamScore,  
                      decoration: const InputDecoration(labelText: 'National Exam Score'),  
                      keyboardType: TextInputType.number,  
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                    ),  
                    const SizedBox(height: 16),  
                    LoadingButton(  
                      loading: _loading,  
                      onPressed: _submit,  
                      child: const Text('Add Demographics'),  
                    ),  
                    const SizedBox(height: 24),  
                    const Text('Existing Demographics:', style: TextStyle(fontWeight: FontWeight.bold)),  
                    const SizedBox(height: 8),  
                    ..._demographics.map((d) => Card(  
                      child: ListTile(  
                        title: Text('Year ${d.academicYear}'),  
                        subtitle: Text(  
                          'Students: ${d.totalStudents} | Girls: ${d.girlsCount} | Boys: ${d.boysCount}\n'  
                          'Passing: ${d.passingRate}% | Exam: ${d.nationalExamScore}'  
                        ),  
                      ),  
                    )),  
                  ],  
                ),  
              ),  
            ),  
    );  
  }  
}