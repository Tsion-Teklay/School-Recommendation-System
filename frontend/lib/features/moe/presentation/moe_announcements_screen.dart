import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../announcements/data/announcement_dtos.dart';
import '../../announcements/data/announcement_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';

/// MoE-only announcements: only ministry-level posts (no schoolId). Hits
/// `/api/announcements/moe`.
class MoeAnnouncementsScreen extends ConsumerStatefulWidget {
  const MoeAnnouncementsScreen({super.key});

  @override
  ConsumerState<MoeAnnouncementsScreen> createState() =>
      _MoeAnnouncementsScreenState();
}

class _MoeAnnouncementsScreenState
    extends ConsumerState<MoeAnnouncementsScreen> {
  bool _loading = false;
  String? _error;
  List<Announcement> _items = const [];

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
      final me = ref.read(authControllerProvider).user;
      final result = await ref
          .read(announcementRepositoryProvider)
          .list(limit: 50);
      setState(() {
        _items = result.items
            .where((a) =>
                a.publisherType == PublisherType.moe &&
                (me == null || a.publisherId == me.id))
            .toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _compose() async {
    final result = await showDialog<AnnouncementInput>(
      context: context,
      builder: (_) => const _MoeComposeDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(announcementRepositoryProvider)
          .createForMoe(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ministry announcement published.')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Announcement a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(announcementRepositoryProvider).delete(a.id);
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
      title: 'Ministry announcements',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              child: Center(
                  child: Text('No ministry announcements yet. Tap New.')),
            )
          else
            for (final a in _items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(a.title,
                                style: theme.textTheme.titleMedium),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'delete') _delete(a);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          Chip(label: Text(a.category.label())),
                          Chip(label: Text(a.urgencyLevel.label())),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.content),
                      const SizedBox(height: 8),
                      Text(
                        a.datePosted.toIso8601String().substring(0, 16),
                        style: theme.textTheme.bodySmall,
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

class _MoeComposeDialog extends StatefulWidget {
  const _MoeComposeDialog();

  @override
  State<_MoeComposeDialog> createState() => _MoeComposeDialogState();
}

class _MoeComposeDialogState extends State<_MoeComposeDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  AnnouncementCategory _category = AnnouncementCategory.policy;
  UrgencyLevel _urgency = UrgencyLevel.normal;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New ministry announcement'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'Content'),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AnnouncementCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in AnnouncementCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label())),
                ],
                onChanged: (v) =>
                    setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<UrgencyLevel>(
                value: _urgency,
                decoration: const InputDecoration(labelText: 'Urgency'),
                items: [
                  for (final u in UrgencyLevel.values)
                    DropdownMenuItem(value: u, child: Text(u.label())),
                ],
                onChanged: (v) => setState(() => _urgency = v ?? _urgency),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty ||
                _contentCtrl.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop(AnnouncementInput(
              title: _titleCtrl.text.trim(),
              content: _contentCtrl.text.trim(),
              category: _category,
              urgencyLevel: _urgency,
              schoolId: null,
            ));
          },
          child: const Text('Publish'),
        ),
      ],
    );
  }
}
