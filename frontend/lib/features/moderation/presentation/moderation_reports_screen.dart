import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../../reports/data/report_dtos.dart';
import '../../reports/data/report_repository.dart';

/// Moderator-only reports queue. Pulls `/api/reports` (MoE auth-gated by
/// the backend) and surfaces a per-report action sheet (dismiss, remove
/// content, warn user, ban user).
class ModerationReportsScreen extends ConsumerStatefulWidget {
  const ModerationReportsScreen({super.key});

  @override
  ConsumerState<ModerationReportsScreen> createState() =>
      _ModerationReportsScreenState();
}

class _ModerationReportsScreenState
    extends ConsumerState<ModerationReportsScreen> {
  bool _loading = false;
  String? _error;
  List<Report> _items = const [];
  ReportStatus? _status = ReportStatus.pending;

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
      final items =
          await ref.read(reportRepositoryProvider).list(status: _status);
      setState(() => _items = items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Report r) async {
    final result = await showDialog<ModeratorActionInput>(
      context: context,
      builder: (_) => _ActionDialog(report: r),
    );
    if (result == null) return;
    try {
      await ref.read(reportRepositoryProvider).takeAction(r.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action recorded: ${result.actionType.label()}')),
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
    final theme = Theme.of(context);
    return ResponsiveShell(
      title: 'Reports queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<ReportStatus?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(
                        value: ReportStatus.pending, label: Text('Pending')),
                    ButtonSegment(
                        value: ReportStatus.reviewed,
                        label: Text('Reviewed')),
                    ButtonSegment(
                        value: ReportStatus.resolved,
                        label: Text('Resolved')),
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
              color: theme.colorScheme.errorContainer,
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
              child: Center(child: Text('No reports in this view.')),
            )
          else
            for (final r in _items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${r.targetType.label()} #${r.targetId}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Chip(label: Text(r.status.label())),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported by ${r.reporterName ?? 'user #${r.reporterId}'} '
                        'on ${r.createdAt.toIso8601String().substring(0, 16)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Reason:', style: theme.textTheme.titleSmall),
                      Text(r.reason),
                      const SizedBox(height: 12),
                      // Use Align (not Row+Spacer) so the trailing
                      // FilledButton.icon actually renders on Flutter web
                      // release builds.
                      if (r.status == ReportStatus.pending)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _act(r),
                            icon: const Icon(Icons.gavel),
                            label: const Text('Take action'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ActionDialog extends StatefulWidget {
  final Report report;
  const _ActionDialog({required this.report});

  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  ModeratorActionType _action = ModeratorActionType.dismiss;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          'Action on ${widget.report.targetType.label()} #${widget.report.targetId}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<ModeratorActionType>(
              value: _action,
              decoration: const InputDecoration(labelText: 'Action'),
              items: [
                for (final a in ModeratorActionType.values)
                  DropdownMenuItem(value: a, child: Text(a.label())),
              ],
              onChanged: (v) => setState(() => _action = v ?? _action),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              minLines: 2,
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            ModeratorActionInput(
              actionType: _action,
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
