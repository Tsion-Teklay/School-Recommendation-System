import 'package:flutter/material.dart';  
import 'package:flutter_riverpod/flutter_riverpod.dart';  
import 'package:go_router/go_router.dart';  
import 'package:url_launcher/url_launcher.dart';  
  
import '../../../core/config.dart';  
import '../../../shared/widgets/responsive_shell.dart';  
import '../../auth/data/auth_repository.dart';  
import '../../verification/data/verification_dtos.dart';  
import '../../verification/data/verification_repository.dart';  
  
class MoeVerificationQueueScreen extends ConsumerStatefulWidget {  
  const MoeVerificationQueueScreen({super.key});  
  
  @override  
  ConsumerState<MoeVerificationQueueScreen> createState() =>  
      _MoeVerificationQueueScreenState();  
}  
  
class _MoeVerificationQueueScreenState  
    extends ConsumerState<MoeVerificationQueueScreen> {  
  bool _loading = false;  
  String? _error;  
  List<VerificationRequest> _items = const [];  
  VerificationRequestStatus? _status = VerificationRequestStatus.pending;  
  
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
      final result = await ref  
          .read(verificationRepositoryProvider)  
          .list(limit: 50, status: _status);  
      setState(() => _items = result.items);  
    } on ApiException catch (e) {  
      setState(() => _error = e.message);  
    } catch (e) {  
      setState(() => _error = e.toString());  
    } finally {  
      if (mounted) setState(() => _loading = false);  
    }  
  }  
  
  Future<void> _openDocument(String relativeUrl) async {  
    final baseUrl = AppConfig.apiBaseUrl;  
    final fullUrl = '$baseUrl$relativeUrl';  
    final uri = Uri.parse(fullUrl);  
    if (await canLaunchUrl(uri)) {  
      await launchUrl(uri, mode: LaunchMode.externalApplication);  
    } else {  
      if (!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(  
        SnackBar(content: Text('Could not open file: $fullUrl')),  
      );  
    }  
  }  
  
  Future<void> _review(VerificationRequest req) async {  
    final result = await showDialog<({VerificationRequestStatus status, String notes})>(  
      context: context,  
      builder: (_) => _ReviewDialog(req: req),  
    );  
    if (result == null) return;  
    try {  
      await ref.read(verificationRepositoryProvider).review(  
            id: req.id,  
            status: result.status,  
            reviewNotes: result.notes,  
          );  
      if (!mounted) return;  
      ScaffoldMessenger.of(context).showSnackBar(  
        SnackBar(content: Text('Marked as ${result.status.label()}')),  
      );  
      await _load();  
    } on ApiException catch (e) {  
      if (!mounted) return;  
      ScaffoldMessenger.of(context)  
          .showSnackBar(SnackBar(content: Text(e.message)));  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return ResponsiveShell(  
      title: 'Verification queue',  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.stretch,  
        children: [  
          Row(  
            children: [  
              Expanded(  
                child: SegmentedButton<VerificationRequestStatus?>(  
                  segments: const [  
                    ButtonSegment(value: null, label: Text('All')),  
                    ButtonSegment(  
                        value: VerificationRequestStatus.pending,  
                        label: Text('Pending')),  
                    ButtonSegment(  
                        value: VerificationRequestStatus.approved,  
                        label: Text('Approved')),  
                    ButtonSegment(  
                        value: VerificationRequestStatus.rejected,  
                        label: Text('Rejected')),  
                  ],  
                  selected: {_status},  
                  onSelectionChanged: (s) {  
                    setState(() => _status = s.first);  
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
          if (_loading && _items.isEmpty)  
            const Padding(  
              padding: EdgeInsets.symmetric(vertical: 48),  
              child: Center(child: CircularProgressIndicator()),  
            )  
          else if (_items.isEmpty)  
            const Padding(  
              padding: EdgeInsets.symmetric(vertical: 48),  
              child: Center(child: Text('No verification requests in this view.')),  
            )  
          else  
            for (final r in _items)   
              _RequestCard(  
                req: r,   
                onReview: () => _review(r),  
                onOpenDocument: _openDocument,  
              ),  
        ],  
      ),  
    );  
  }  
}  
  
class _RequestCard extends StatelessWidget {  
  final VerificationRequest req;  
  final VoidCallback onReview;  
  final Future<void> Function(String) onOpenDocument;  
  const _RequestCard({  
    required this.req,   
    required this.onReview,  
    required this.onOpenDocument,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    final theme = Theme.of(context);  
    return Card(  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Row(  
              children: [  
                Expanded(  
                  child: Text(req.schoolName ?? 'School #${req.schoolId}',  
                      style: theme.textTheme.titleMedium),  
                ),  
                Chip(label: Text(req.status.label())),  
              ],  
            ),  
            const SizedBox(height: 4),  
            Text(  
              'Submitted by ${req.submitterName ?? 'admin #${req.submittedById}'} '  
              'on ${req.submittedAt.toIso8601String().substring(0, 16)}',  
              style: theme.textTheme.bodySmall,  
            ),  
            if (req.notes?.isNotEmpty ?? false) ...[  
              const SizedBox(height: 8),  
              Text('Submitter notes:',  
                  style: theme.textTheme.titleSmall),  
              Text(req.notes!),  
            ],  
            if (req.documents.isNotEmpty) ...[  
              const SizedBox(height: 8),  
              Text('Documents (${req.documents.length}):',  
                  style: theme.textTheme.titleSmall),  
              for (final d in req.documents)  
                Padding(  
                  padding: const EdgeInsets.symmetric(vertical: 2),  
                  child: InkWell(  
                    onTap: () => onOpenDocument(d.url),  
                    child: Row(  
                      children: [  
                        const Icon(Icons.description_outlined, size: 16),  
                        const SizedBox(width: 6),  
                        Expanded(  
                          child: Text(  
                            d.originalName ?? d.url,  
                            overflow: TextOverflow.ellipsis,  
                            style: TextStyle(  
                              color: theme.colorScheme.primary,  
                              decoration: TextDecoration.underline,  
                            ),  
                          ),  
                        ),  
                      ],  
                    ),  
                  ),  
                ),  
            ],  
            if (req.reviewNotes?.isNotEmpty ?? false) ...[  
              const SizedBox(height: 8),  
              Text('Reviewer notes:', style: theme.textTheme.titleSmall),  
              Text(req.reviewNotes!),  
            ],  
            const SizedBox(height: 12),  
            Wrap(  
              alignment: WrapAlignment.spaceBetween,  
              spacing: 12,  
              runSpacing: 8,  
              crossAxisAlignment: WrapCrossAlignment.center,  
              children: [  
                OutlinedButton.icon(  
                  icon: const Icon(Icons.school),  
                  label: const Text('Open school'),  
                  onPressed: () =>  
                      context.go('/schools/${req.schoolId}'),  
                ),  
                if (req.status == VerificationRequestStatus.pending)  
                  FilledButton.icon(  
                    onPressed: onReview,  
                    icon: const Icon(Icons.gavel),  
                    label: const Text('Review'),  
                  ),  
              ],  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}  
  
class _ReviewDialog extends StatefulWidget {  
  final VerificationRequest req;  
  const _ReviewDialog({required this.req});  
  
  @override  
  State<_ReviewDialog> createState() => _ReviewDialogState();  
}  
  
class _ReviewDialogState extends State<_ReviewDialog> {  
  VerificationRequestStatus _decision =  
      VerificationRequestStatus.approved;  
  final _notesCtrl = TextEditingController();  
  
  @override  
  void dispose() {  
    _notesCtrl.dispose();  
    super.dispose();  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, minWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.req.schoolName ?? 'Review request',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              SegmentedButton<VerificationRequestStatus>(
                segments: const [
                  ButtonSegment(
                      value: VerificationRequestStatus.approved,
                      label: Text('Approve')),
                  ButtonSegment(
                      value: VerificationRequestStatus.rejected,
                      label: Text('Reject')),
                ],
                selected: {_decision},
                onSelectionChanged: (s) =>
                    setState(() => _decision = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Review notes (optional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 4,
                maxLines: 8,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      (status: _decision, notes: _notesCtrl.text.trim()),
                    ),
                    child: const Text('Submit decision'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );  
  }  
}