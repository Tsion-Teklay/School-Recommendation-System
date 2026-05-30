import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';  
  
import '../../../core/design_system.dart';
import '../../../shared/widgets/responsive_shell.dart';  
import '../../../shared/widgets/loading_button.dart';  
import '../../../shared/widgets/custom_components.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/illustrations.dart';
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
  List<PickedFile> _pickedFiles = [];  
  
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      // Validate file size (10MB limit)
      if (file.size > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 10MB limit')),
        );
        return;
      }

      // Get MIME type
      String? contentType;
      if (file.extension != null) {
        switch (file.extension!.toLowerCase()) {
          case 'pdf':
            contentType = 'application/pdf';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
        }
      }

      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file')),
        );
        return;
      }

      setState(() {
        _pickedFiles.add(PickedFile(
          filename: file.name,
          bytes: file.bytes!,
          contentType: contentType,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
    }
  }  
  
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    
    if (_pickedFiles.isEmpty) {
      setState(() => _error = 'Please upload at least one document');
      return;
    }
    
    // Check if user is authenticated
    final authController = ref.read(authControllerProvider);
    if (!authController.isAuthenticated) {
      setState(() => _error = 'You must be logged in to submit achievements');
      return;
    }
    
    print('Submitting achievement: schoolId=${widget.schoolId}, title=${_title.text.trim()}, year=${_year.text}');
    
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {
      await ref.read(achievementRepositoryProvider).createAchievement(
        schoolId: widget.schoolId,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        year: int.parse(_year.text),
        documents: _pickedFiles,
      );  
        
      // Clear form fields
      _title.clear();
      _description.clear();
      _year.text = DateTime.now().year.toString();
      _pickedFiles = [];  
        
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
  
  Color _getTierColor(String? tier) {
    switch (tier) {
      case 'GOLD': return const Color(0xFF60A5FA); // Light blue for premium feel
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(  
                key: _form,  
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.stretch,  
                  children: [  
                    if (_error != null) ...[  
                      Text(_error!, style: const TextStyle(color: Colors.red)),  
                      SpacingHelper.lg,
                    ],  
                    Card(  
                      child: Padding(  
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(  
                          crossAxisAlignment: CrossAxisAlignment.stretch,  
                          children: [  
                            const Text('Add New Achievement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),  
                            SpacingHelper.lg,
                            TextFormField(  
                              controller: _title,  
                              decoration: const InputDecoration(labelText: 'Title *'),  
                              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,  
                            ),  
                            SpacingHelper.md,
                            TextFormField(  
                              controller: _description,  
                              decoration: const InputDecoration(labelText: 'Description (optional)'),  
                              maxLines: 3,  
                            ),  
                            SpacingHelper.md,
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Document'),
                            ),
                            if (_pickedFiles.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Uploaded documents:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    SpacingHelper.xs,
                                    ..._pickedFiles.asMap().entries.map((entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.description, size: 16),
                                          SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              entry.value.filename,
                                              style: const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              _pickedFiles.removeAt(entry.key);
                                            }),
                                            child: const Icon(Icons.close, size: 16, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
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
                    SpacingHelper.xxl,
                    const Text('Existing Achievements:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SpacingHelper.md,
                    if (_achievements.isEmpty)
                      EmptyStateCard(
                        illustrationType: IllustrationType.emptyAchievements,
                        title: 'No achievements yet',
                        description: 'Submit your school achievements to build your reputation and attract more parents.',
                      )
                    else  
                      ..._achievements.map((a) => Card(
                        child: ListTile(
                          leading: a.tier != null
                              ? CircleAvatar(
                                  backgroundColor: _getTierColor(a.tier),
                                  child: Text(a.tier![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.pending, color: Colors.white, size: 20),
                                ),
                          title: Text(a.title),
                          subtitle: Text('${a.year}${a.score != null ? ' • ${a.score} pts' : ' • Pending review'}'),  
                          trailing: Row(  
                            mainAxisSize: MainAxisSize.min,  
                            children: [  
                              AppBadge(
                                label: a.status,
                                color: _getStatusColor(a.status),
                                small: true,
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