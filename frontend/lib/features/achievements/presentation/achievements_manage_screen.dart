import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../../shared/widgets/loading_button.dart';  
import '../../auth/data/auth_repository.dart' show ApiException;
import '../../auth/state/auth_controller.dart';
import '../data/achievement_repository.dart';  
import '../data/achievement_dtos.dart';  
  
class AchievementsManageScreen extends ConsumerStatefulWidget {  
  final int schoolId;  
  const AchievementsManageScreen({super.key, required this.schoolId});  
  
  @override  
  ConsumerState<AchievementsManageScreen> createState() => _AchievementsManageScreenState();  
}  
  
class _AchievementsManageScreenState extends ConsumerState<AchievementsManageScreen> {  
  final _form = GlobalKey<FormState>();  
  final _title = TextEditingController();  
  final _description = TextEditingController();  
  final _year = TextEditingController(text: DateTime.now().year.toString());  
  String _selectedTier = 'BRONZE';  
  
  bool _loading = false;  
  String? _error;  
  List<Achievement> _achievements = [];  
  
  @override  
  void initState() {  
    super.initState();  
    _load();  
  }  
  
  @override  
  void dispose() {  
    _title.dispose();  
    _description.dispose();  
    _year.dispose();  
    super.dispose();  
  }  
  
  Future<void> _load() async {  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      final data = await ref.read(achievementRepositoryProvider).getSchoolAchievements(widget.schoolId);  
      setState(() => _achievements = data);  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _submit() async {  
    if (!_form.currentState!.validate()) return;  
    
    // Check if user is authenticated
    final authController = ref.read(authControllerProvider);
    if (!authController.isAuthenticated) {
      setState(() => _error = 'You must be logged in to submit achievements');
      return;
    }
    
    print('Submitting achievement: schoolId=${widget.schoolId}, title=${_title.text.trim()}, tier=$_selectedTier, year=${_year.text}');
    
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      await ref.read(achievementRepositoryProvider).createAchievement(  
        schoolId: widget.schoolId,  
        title: _title.text.trim(),  
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),  
        tier: _selectedTier,  
        year: int.parse(_year.text),  
      );  
        
      // Clear form fields  
      _title.clear();  
      _description.clear();  
      _year.text = DateTime.now().year.toString();  
      _selectedTier = 'BRONZE';  
        
      // Reload achievements list  
      await _load();  
        
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(  
        const SnackBar(content: Text('Achievement submitted for review')),  
      );  
    } on ApiException catch (e) {
      String errorMessage = e.message;
      if (e.statusCode == 401) {
        errorMessage = 'You must be logged in to submit achievements';
      } else if (e.statusCode == 403) {
        errorMessage = 'You do not have permission to submit achievements';
      } else if (e.code == 'VALIDATION_ERROR' && e.details != null) {
        // Show specific validation errors
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
  
  Future<void> _deleteAchievement(int id) async {  
    final confirmed = await showDialog<bool>(  
      context: context,  
      builder: (_) => AlertDialog(  
        title: const Text('Delete Achievement'),  
        content: const Text('Are you sure you want to delete this achievement?'),  
        actions: [  
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),  
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),  
        ],  
      ),  
    );  
    if (confirmed != true) return;  
  
    setState(() => _loading = true);  
    try {  
      await ref.read(achievementRepositoryProvider).delete(id);  
      await _load();  
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(  
        const SnackBar(content: Text('Achievement deleted')),  
      );  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Color _getStatusColor(String status) {  
    switch (status) {  
      case 'PENDING': return Colors.orange;  
      case 'APPROVED': return Colors.green;  
      case 'REJECTED': return Colors.red;  
      default: return Colors.grey;  
    }  
  }  
  
  Color _getTierColor(String tier) {  
    switch (tier) {  
      case 'GOLD': return Colors.amber;  
      case 'SILVER': return Colors.grey;  
      case 'BRONZE': return Colors.brown;  
      default: return Colors.grey;  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return ResponsiveShell(  
      title: 'School Achievements',  
      child: _loading && _achievements.isEmpty  
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
                    Card(  
                      child: Padding(  
                        padding: const EdgeInsets.all(16),  
                        child: Column(  
                          crossAxisAlignment: CrossAxisAlignment.stretch,  
                          children: [  
                            const Text('Add New Achievement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),  
                            const SizedBox(height: 16),  
                            TextFormField(  
                              controller: _title,  
                              decoration: const InputDecoration(labelText: 'Title *'),  
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,  
                            ),  
                            const SizedBox(height: 12),  
                            TextFormField(  
                              controller: _description,  
                              decoration: const InputDecoration(labelText: 'Description (optional)'),  
                              maxLines: 3,  
                            ),  
                            const SizedBox(height: 12),  
                            DropdownButtonFormField<String>(  
                              value: _selectedTier,  
                              decoration: const InputDecoration(labelText: 'Tier *'),  
                              items: const [  
                                DropdownMenuItem(value: 'GOLD', child: Text('Gold (100 pts)')),  
                                DropdownMenuItem(value: 'SILVER', child: Text('Silver (50 pts)')),  
                                DropdownMenuItem(value: 'BRONZE', child: Text('Bronze (25 pts)')),  
                              ],  
                              onChanged: (v) => setState(() => _selectedTier = v!),  
                            ),  
                            const SizedBox(height: 12),  
                            TextFormField(  
                              controller: _year,  
                              decoration: const InputDecoration(labelText: 'Year *'),  
                              keyboardType: TextInputType.number,  
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                            ),  
                            const SizedBox(height: 16),  
                            LoadingButton(  
                              loading: _loading,  
                              onPressed: _submit,  
                              child: const Text('Submit Achievement'),  
                            ),  
                          ],  
                        ),  
                      ),  
                    ),  
                    const SizedBox(height: 24),  
                    const Text('Existing Achievements:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),  
                    const SizedBox(height: 12),  
                    if (_achievements.isEmpty)  
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No achievements yet')))  
                    else  
                      ..._achievements.map((a) => Card(  
                        child: ListTile(  
                          leading: CircleAvatar(  
                            backgroundColor: _getTierColor(a.tier),  
                            child: Text(a.tier[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),  
                          ),  
                          title: Text(a.title),  
                          subtitle: Text('${a.year} • ${a.score} pts'),  
                          trailing: Row(  
                            mainAxisSize: MainAxisSize.min,  
                            children: [  
                              Chip(  
                                label: Text(a.status),  
                                backgroundColor: _getStatusColor(a.status).withOpacity(0.2),  
                              ),  
                              if (a.status == 'PENDING')  
                                IconButton(  
                                  icon: const Icon(Icons.delete, color: Colors.red),  
                                  onPressed: () => _deleteAchievement(a.id),  
                                ),  
                            ],  
                          ),  
                          onTap: () => context.go('/admin/schools/${widget.schoolId}/achievements/${a.id}'),  
                        ),  
                      )),  
                  ],  
                ),  
              ),  
            ),  
    );  
  }  
}