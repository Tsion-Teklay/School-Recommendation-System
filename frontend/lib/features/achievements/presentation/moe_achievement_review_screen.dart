import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/custom_components.dart';
import '../../../core/config.dart';
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
        // Load achievements by status (APPROVED or REJECTED)
        final data = await ref.read(achievementRepositoryProvider).getAchievementsByStatus(_statusFilter!);
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
    final result = await showDialog<({String status, String notes, String? tier})>(  
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
        tier: result.tier,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(_statusFilter == null
                    ? 'No pending achievements to review'
                    : _statusFilter == 'APPROVED'
                        ? 'No approved achievements'
                        : 'No rejected achievements'),
              ),
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
                          backgroundColor: a.tier != null ? _getTierColor(a.tier) : Colors.grey,
                          child: a.tier != null
                              ? Text(a.tier![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              : const Icon(Icons.pending, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${a.schoolName ?? "School #${a.schoolId}"} • ${a.year}${a.score != null ? ' • ${a.score} pts' : ' • Pending review'}'),
                            ],
                          ),
                        ),  
                        AppBadge(
                          label: a.status,
                          color: _getStatusColor(a.status),
                          small: true,
                        ),  
                      ],  
                    ),  
                    if (a.description != null) ...[
                      const SizedBox(height: 8),
                      Text(a.description!),
                    ],
                    if (a.documents != null && a.documents!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...a.documents!.map((docUrl) => Padding(
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