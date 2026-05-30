import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
  
import '../../../shared/utils/error_handler.dart';
import '../../../shared/utils/message_helper.dart';
import '../../../shared/widgets/responsive_shell.dart';  
import '../../../shared/widgets/loading_button.dart';  
import '../data/achievement_repository.dart';  
import '../data/achievement_dtos.dart';  
  
class StaffBreakdownScreen extends ConsumerStatefulWidget {  
  final int schoolId;  
  const StaffBreakdownScreen({super.key, required this.schoolId});  
  
  @override  
  ConsumerState<StaffBreakdownScreen> createState() => _StaffBreakdownScreenState();  
}  
  
class _StaffBreakdownScreenState extends ConsumerState<StaffBreakdownScreen> {  
  final _form = GlobalKey<FormState>();  
  final _countController = TextEditingController();  
  String _selectedLevel = 'DEGREE';  
  
  bool _loading = false;  
  String? _error;  
  List<StaffBreakdown> _breakdown = [];  
  
  @override  
  void initState() {  
    super.initState();  
    _load();  
  }  
  
  @override  
  void dispose() {  
    _countController.dispose();  
    super.dispose();  
  }  
  
  Future<void> _load() async {  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      final data = await ref.read(achievementRepositoryProvider).getSchoolStaffBreakdown(widget.schoolId);  
      setState(() => _breakdown = data);  
    } catch (e) {  
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _add() async {  
    if (!_form.currentState!.validate()) return;  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      final count = int.parse(_countController.text);
      await ref.read(achievementRepositoryProvider).createStaffBreakdown(  
        schoolId: widget.schoolId,  
        educationLevel: _selectedLevel,  
        count: count,  
      );  
      _countController.clear();  
      await _load();  
      if (mounted) MessageHelper.showSuccess(context, 'Staff breakdown added successfully');  
    } catch (e) {  
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _update(int id, int newCount) async {  
    setState(() => _loading = true);  
    try {  
      await ref.read(achievementRepositoryProvider).updateStaffBreakdown(  
        id: id,  
        count: newCount,  
      );  
      await _load();  
      if (mounted) MessageHelper.showSuccess(context, 'Staff breakdown updated successfully');  
    } catch (e) {  
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _delete(int id) async {  
    final confirmed = await MessageHelper.showConfirmationDialog(  
      context,  
      'Delete Entry',  
      'Are you sure you want to delete this entry?',  
      confirmText: 'Delete',  
      isDestructive: true,  
    );  
    if (confirmed != true) return;  
  
    setState(() => _loading = true);  
    try {  
      await ref.read(achievementRepositoryProvider).deleteStaffBreakdown(id);  
      await _load();  
      if (mounted) MessageHelper.showSuccess(context, 'Entry deleted successfully');  
    } catch (e) {  
      setState(() => _error = ErrorHandler.getUserFriendlyMessage(e));  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return ResponsiveShell(  
      title: 'Staff Breakdown',  
      child: _loading && _breakdown.isEmpty  
          ? const Center(child: CircularProgressIndicator())  
          : SingleChildScrollView(  
              padding: const EdgeInsets.all(16),  
              child: Column(  
                crossAxisAlignment: CrossAxisAlignment.stretch,  
                children: [  
                  if (_error != null) ...[  
                    Text(_error!, style: const TextStyle(color: Colors.red)),  
                    const SizedBox(height: 16),  
                  ],  
                  Card(  
                    child: Padding(  
                      padding: const EdgeInsets.all(16),  
                      child: Form(  
                        key: _form,  
                        child: Column(  
                          crossAxisAlignment: CrossAxisAlignment.stretch,  
                          children: [  
                            const Text('Add Staff Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),  
                            const SizedBox(height: 16),  
                            DropdownButtonFormField<String>(  
                              value: _selectedLevel,  
                              decoration: const InputDecoration(labelText: 'Education Level *'),  
                              items: const [  
                                DropdownMenuItem(value: 'PHD', child: Text('PhD')),  
                                DropdownMenuItem(value: 'MASTERS', child: Text('Masters')),  
                                DropdownMenuItem(value: 'DEGREE', child: Text('Degree')),  
                                DropdownMenuItem(value: 'DIPLOMA', child: Text('Diploma')),  
                                DropdownMenuItem(value: 'CERTIFICATE', child: Text('Certificate')),  
                              ],  
                              onChanged: (v) => setState(() => _selectedLevel = v!),  
                            ),  
                            const SizedBox(height: 12),  
                            TextFormField(  
                              controller: _countController,  
                              decoration: const InputDecoration(labelText: 'Count *'),  
                              keyboardType: TextInputType.number,  
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Required';
                                final count = int.tryParse(v!);
                                if (count == null) return 'Please enter a valid number';
                                if (count < 0) return 'Count cannot be negative';
                                return null;
                              },  
                            ),  
                            const SizedBox(height: 16),  
                            LoadingButton(  
                              loading: _loading,  
                              onPressed: _add,  
                              child: const Text('Add Entry'),  
                            ),  
                          ],  
                        ),  
                      ),  
                    ),  
                  ),  
                  const SizedBox(height: 24),  
                  const Text('Current Staff Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),  
                  const SizedBox(height: 12),  
                  if (_breakdown.isEmpty)  
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No entries yet')))  
                  else  
                    Card(  
                      child: Column(  
                        children: [  
                          // Header row  
                          Padding(  
                            padding: const EdgeInsets.all(12),  
                            child: Row(  
                              children: const [  
                                Expanded(child: Text('Education Level', style: TextStyle(fontWeight: FontWeight.bold))),  
                                Expanded(child: Text('Count', style: TextStyle(fontWeight: FontWeight.bold))),  
                                Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),  
                              ],  
                            ),  
                          ),  
                          const Divider(),  
                          // Data rows  
                          ..._breakdown.map((b) => _StaffBreakdownRow(  
                            breakdown: b,  
                            onUpdate: (count) => _update(b.id, count),  
                            onDelete: () => _delete(b.id),  
                          )),  
                        ],  
                      ),  
                    ),  
                ],  
              ),  
            ),  
    );  
  }  
}  
  
class _StaffBreakdownRow extends StatefulWidget {  
  final StaffBreakdown breakdown;  
  final Function(int) onUpdate;  
  final VoidCallback onDelete;  
  const _StaffBreakdownRow({required this.breakdown, required this.onUpdate, required this.onDelete});  
  
  @override  
  State<_StaffBreakdownRow> createState() => _StaffBreakdownRowState();  
}  
  
class _StaffBreakdownRowState extends State<_StaffBreakdownRow> {  
  late TextEditingController _countController;  
  bool _isEditing = false;  
  
  @override  
  void initState() {  
    super.initState();  
    _countController = TextEditingController(text: widget.breakdown.count.toString());  
  }  
  
  @override  
  void dispose() {  
    _countController.dispose();  
    super.dispose();  
  }  
  
  void _save() {  
    final count = int.tryParse(_countController.text);  
    if (count != null) {  
      widget.onUpdate(count);  
      setState(() => _isEditing = false);  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Column(  
      children: [  
        Padding(  
          padding: const EdgeInsets.all(12),  
          child: Row(  
            children: [  
              Expanded(child: Text(widget.breakdown.educationLevel)),  
              Expanded(  
                child: _isEditing  
                    ? TextField(  
                        controller: _countController,  
                        keyboardType: TextInputType.number,  
                        decoration: const InputDecoration(isDense: true),  
                      )  
                    : Text(widget.breakdown.count.toString()),  
              ),  
              Expanded(  
                child: Row(  
                  children: [  
                    if (_isEditing) ...[  
                      IconButton(  
                        icon: const Icon(Icons.check, color: Colors.green),  
                        onPressed: _save,  
                      ),  
                      IconButton(  
                        icon: const Icon(Icons.close),  
                        onPressed: () {  
                          _countController.text = widget.breakdown.count.toString();  
                          setState(() => _isEditing = false);  
                        },  
                      ),  
                    ] else ...[  
                      IconButton(  
                        icon: const Icon(Icons.edit),  
                        onPressed: () => setState(() => _isEditing = true),  
                      ),  
                      IconButton(  
                        icon: const Icon(Icons.delete, color: Colors.red),  
                        onPressed: widget.onDelete,  
                      ),  
                    ],  
                  ],  
                ),  
              ),  
            ],  
          ),  
        ),  
        const Divider(),  
      ],  
    );  
  }  
}