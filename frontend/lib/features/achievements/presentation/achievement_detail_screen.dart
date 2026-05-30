import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../core/config.dart';
import '../data/achievement_repository.dart';
import '../data/achievement_dtos.dart';  
  
class AchievementDetailScreen extends ConsumerStatefulWidget {  
  final int schoolId;  
  final int achievementId;  
  const AchievementDetailScreen({super.key, required this.schoolId, required this.achievementId});  
  
  @override  
  ConsumerState<AchievementDetailScreen> createState() => _AchievementDetailScreenState();  
}  
  
class _AchievementDetailScreenState extends ConsumerState<AchievementDetailScreen> {  
  final _form = GlobalKey<FormState>();  
  final _title = TextEditingController();  
  final _description = TextEditingController();  
  final _year = TextEditingController();  
  String? _selectedTier;  
  
  bool _loading = false;  
  String? _error;  
  Achievement? _achievement;  
  
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
      final data = await ref.read(achievementRepositoryProvider).getById(widget.achievementId);  
      setState(() {  
        _achievement = data;  
        if (data != null) {
          _title.text = data.title;
          _description.text = data.description ?? '';
          _year.text = data.year.toString();
          _selectedTier = data.tier;
        }  
      });  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _update() async {  
    if (!_form.currentState!.validate()) return;  
    setState(() {  
      _loading = true;  
      _error = null;  
    });  
    try {  
      await ref.read(achievementRepositoryProvider).update(
        id: widget.achievementId,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        year: int.parse(_year.text),
      );  
      await _load();  
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(  
        const SnackBar(content: Text('Achievement updated')),  
      );  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _delete() async {  
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
      await ref.read(achievementRepositoryProvider).delete(widget.achievementId);  
      if (mounted) {  
        context.pop();  
        ScaffoldMessenger.of(context).showSnackBar(  
          const SnackBar(content: Text('Achievement deleted')),  
        );  
      }  
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
  
  @override  
  Widget build(BuildContext context) {  
    if (_loading && _achievement == null) {  
      return ResponsiveShell(  
        title: 'Achievement Details',  
        child: const Center(child: CircularProgressIndicator()),  
      );  
    }  
  
    if (_achievement == null) {  
      return ResponsiveShell(  
        title: 'Achievement Details',  
        child: Center(child: Text(_error ?? 'Achievement not found')),  
      );  
    }  
  
    final canEdit = _achievement!.status == 'PENDING';  
  
    return ResponsiveShell(  
      title: 'Achievement Details',  
      child: SingleChildScrollView(  
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
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.start,  
                  children: [  
                    Row(  
                      children: [  
                        Chip(  
                          label: Text(_achievement!.status),  
                          backgroundColor: _getStatusColor(_achievement!.status).withOpacity(0.2),  
                        ),  
                        const SizedBox(width: 8),  
                        Text('${_achievement!.score ?? 0} pts', style: const TextStyle(fontWeight: FontWeight.bold)),  
                      ],  
                    ),  
                    const SizedBox(height: 16),  
                    if (_achievement!.reviewNotes != null) ...[  
                      const Text('Review Notes:', style: TextStyle(fontWeight: FontWeight.bold)),  
                      Text(_achievement!.reviewNotes!),  
                      const SizedBox(height: 16),  
                    ],  
                    if (_achievement!.reviewedAt != null) ...[  
                      Text('Reviewed: ${_achievement!.reviewedAt!.toLocal().toString().split('.')[0]}'),  
                      const SizedBox(height: 16),  
                    ],  
                  ],  
                ),  
              ),  
            ),  
            const SizedBox(height: 16),  
            if (canEdit)  
              Form(  
                key: _form,  
                child: Card(  
                  child: Padding(  
                    padding: const EdgeInsets.all(16),  
                    child: Column(  
                      crossAxisAlignment: CrossAxisAlignment.stretch,  
                      children: [  
                        const Text('Edit Achievement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),  
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
                        TextFormField(  
                          controller: _year,  
                          decoration: const InputDecoration(labelText: 'Year *'),  
                          keyboardType: TextInputType.number,  
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,  
                        ),  
                        const SizedBox(height: 16),  
                        Row(  
                          children: [  
                            Expanded(  
                              child: LoadingButton(  
                                loading: _loading,  
                                onPressed: _update,  
                                child: const Text('Update'),  
                              ),  
                            ),  
                            const SizedBox(width: 12),  
                            Expanded(  
                              child: OutlinedButton(  
                                onPressed: _delete,  
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),  
                                child: const Text('Delete'),  
                              ),  
                            ),  
                          ],  
                        ),  
                      ],  
                    ),  
                  ),  
                ),  
              )  
            else  
              Card(  
                child: Padding(  
                  padding: const EdgeInsets.all(16),  
                  child: Column(  
                    crossAxisAlignment: CrossAxisAlignment.start,  
                    children: [  
                      Text(_achievement!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),  
                      const SizedBox(height: 8),  
                      if (_achievement!.description != null) ...[  
                        Text(_achievement!.description!),  
                        const SizedBox(height: 8),  
                      ],  
                      Text('Tier: ${_achievement!.tier ?? "Pending review"}'),
                      Text('Year: ${_achievement!.year}'),
                      Text('Score: ${_achievement!.score ?? 0} pts'),
                      Text('Submitted: ${_achievement!.submittedAt.toLocal().toString().split('.')[0]}'),
                      if (_achievement!.documents != null && _achievement!.documents!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._achievement!.documents!.map((docUrl) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: InkWell(
                            onTap: () async {
                              final fullUrl = '${AppConfig.apiBaseUrl}$docUrl';
                              final uri = Uri.parse(fullUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.description, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    docUrl.split('/').last,
                                    style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],  
                    ],  
                  ),  
                ),  
              ),  
          ],  
        ),  
      ),  
    );  
  }  
}