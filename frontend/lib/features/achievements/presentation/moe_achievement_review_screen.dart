import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../auth/data/auth_repository.dart' show ApiException;
import '../data/achievement_repository.dart';  
import '../data/achievement_dtos.dart';  
import 'achievement_review_dialog.dart';  
  
class MoeAchievementReviewScreen extends ConsumerStatefulWidget {  
  const MoeAchievementReviewScreen({super.key});  
  
  @override  
  ConsumerState<MoeAchievementReviewScreen> createState() => _MoeAchievementReviewScreenState();  
}  
  
class _MoeAchievementReviewScreenState extends ConsumerState<MoeAchievementReviewScreen> {  
  bool _loading = false;  
  String? _error;  
  List<Achievement> _achievements = [];  
  String? _statusFilter;  
  
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
      if (_statusFilter == null) {  
        // Load pending achievements for review  
        final data = await ref.read(achievementRepositoryProvider).getPendingAchievements();  
        setState(() => _achievements = data);
      } else {  
        // For other filters, we'd need a backend endpoint - for now show all pending  
        final data = await ref.read(achievementRepositoryProvider).getPendingAchievements();  
        setState(() => _achievements = data);
      }
    } on ApiException catch (e) {
      String errorMessage = e.message;
      if (e.statusCode == 401) {
        errorMessage = 'You must be logged in to view achievements';
      } else if (e.statusCode == 403) {
        errorMessage = 'You do not have permission to view achievements';
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
  
  Future<void> _review(Achievement achievement) async {  
    final result = await showDialog<({String status, String notes})>(  
      context: context,  
      builder: (_) => AchievementReviewDialog(achievement: achievement),  
    );  
    if (result == null) return;  
  
    setState(() => _loading = true);  
    try {  
      await ref.read(achievementRepositoryProvider).reviewAchievement(  
        id: achievement.id,  
        status: result.status,  
        reviewNotes: result.notes.isEmpty ? null : result.notes,  
      );  
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(  
        SnackBar(content: Text('Marked as ${result.status}')),  
      );  
      await _load();  
    } on ApiException catch (e) {
      String errorMessage = e.message;
      if (e.statusCode == 401) {
        errorMessage = 'You must be logged in to review achievements';
      } else if (e.statusCode == 403) {
        errorMessage = 'You do not have permission to review achievements';
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
      title: 'Achievement Review Queue',  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.stretch,  
        children: [  
          Row(  
            children: [  
              Expanded(  
                child: SegmentedButton<String?>(  
                  segments: const [  
                    ButtonSegment(value: null, label: Text('Pending')),  
                    ButtonSegment(value: 'APPROVED', label: Text('Approved')),  
                    ButtonSegment(value: 'REJECTED', label: Text('Rejected')),  
                  ],  
                  selected: {_statusFilter},  
                  onSelectionChanged: (s) {  
                    setState(() => _statusFilter = s.first);  
                    _load();  
                  },  
                ),  
              ),  
              const SizedBox(width: 12),  
              IconButton(  
                tooltip: 'Refresh',  
                onPressed: _loading ? null : _load,  
                icon: const Icon(Icons.refresh),  
              ),  
            ],  
          ),  
          const SizedBox(height: 16),  
          if (_error != null)  
            Card(  
              color: Theme.of(context).colorScheme.errorContainer,  
              child: Padding(  
                padding: const EdgeInsets.all(12),  
                child: Text(_error!),  
              ),  
            ),  
          if (_loading && _achievements.isEmpty)  
            const Padding(  
              padding: EdgeInsets.symmetric(vertical: 48),  
              child: Center(child: CircularProgressIndicator()),  
            )  
          else if (_achievements.isEmpty)  
            const Padding(  
              padding: EdgeInsets.symmetric(vertical: 48),  
              child: Center(child: Text('No achievements to review')),  
            )  
          else  
            ..._achievements.map((a) => Card(  
              child: Padding(  
                padding: const EdgeInsets.all(16),  
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.start,  
                  children: [  
                    Row(  
                      children: [  
                        CircleAvatar(  
                          backgroundColor: _getTierColor(a.tier),  
                          child: Text(a.tier[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),  
                        ),  
                        const SizedBox(width: 12),  
                        Expanded(  
                          child: Column(  
                            crossAxisAlignment: CrossAxisAlignment.start,  
                            children: [  
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${a.schoolName ?? "School #${a.schoolId}"} • ${a.year} • ${a.score} pts'),  
                            ],  
                          ),  
                        ),  
                        Chip(  
                          label: Text(a.status),  
                          backgroundColor: _getStatusColor(a.status).withOpacity(0.2),  
                        ),  
                      ],  
                    ),  
                    if (a.description != null) ...[  
                      const SizedBox(height: 8),  
                      Text(a.description!),  
                    ],  
                    if (a.reviewNotes != null) ...[  
                      const SizedBox(height: 8),  
                      Text('Review Notes: ${a.reviewNotes!}', style: const TextStyle(fontStyle: FontStyle.italic)),  
                    ],  
                    const SizedBox(height: 12),  
                    if (a.status == 'PENDING')  
                      FilledButton.icon(  
                        onPressed: () => _review(a),  
                        icon: const Icon(Icons.gavel),  
                        label: const Text('Review'),  
                      ),  
                  ],  
                ),  
              ),  
            )),  
        ],  
      ),  
    );  
  }  
}