import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../announcements/data/announcement_dtos.dart';
import '../../announcements/data/announcement_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../../schools/data/school_dtos.dart';
import '../../schools/data/school_repository.dart';

/// School-admin announcement management. Lists announcements published by
/// the current admin (filtered client-side on `publisherId == me.id`) and
/// hosts a compose dialog that POSTs to `/api/announcements/school`.
class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  bool _loading = false;
  String? _error;
  List<Announcement> _items = const [];
  List<School> _mySchools = const [];

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
      final repo = ref.read(announcementRepositoryProvider);
      final result = await repo.list(limit: 50);
      final mySchools =
          await ref.read(schoolRepositoryProvider).list(
                const SchoolListFilters(limit: 100),
              );
      setState(() {
        _items = result.items
            .where((a) => me != null && a.publisherId == me.id)
            .toList();
        _mySchools = mySchools.items;
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
    if (_mySchools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need at least one school to post.')),
      );
      return;
    }
    final result = await showDialog<AnnouncementInput>(
      context: context,
      builder: (_) => _AnnouncementComposeDialog(
        schools: _mySchools,
        forMoE: false,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(announcementRepositoryProvider)
          .createForSchool(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted.')),
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
      if (!mounted) return;
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
      title: 'My announcements',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/admin'),
      ),
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
              child: Center(
                child: Text('No announcements yet. Tap New to publish one.'),
              ),
            )
          else
            for (final a in _items)
              _AnnouncementTile(
                announcement: a,
                onDelete: () => _delete(a),
              ),
        ],
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onDelete;
  const _AnnouncementTile({
    required this.announcement,
    required this.onDelete,
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
                  child: Text(announcement.title,
                      style: theme.textTheme.titleMedium),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                    label: Text(announcement.category.label()),
                    visualDensity: VisualDensity.compact),
                Chip(
                    label: Text(announcement.urgencyLevel.label()),
                    visualDensity: VisualDensity.compact),
                Chip(
                  label: Text(announcement.publisherType.label()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(announcement.content),
            const SizedBox(height: 8),
            Text(
              announcement.datePosted.toIso8601String().substring(0, 16),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reused by both the school-admin and MoE flows. Pass `forMoE = true` and
/// an empty `schools` list when posting a ministry-level announcement.
class _AnnouncementComposeDialog extends StatefulWidget {
  final List<School> schools;
  final bool forMoE;
  const _AnnouncementComposeDialog({
    required this.schools,
    required this.forMoE,
  });

  @override
  State<_AnnouncementComposeDialog> createState() =>
      _AnnouncementComposeDialogState();
}

class _AnnouncementComposeDialogState
    extends State<_AnnouncementComposeDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  AnnouncementCategory _category = AnnouncementCategory.other;
  UrgencyLevel _urgency = UrgencyLevel.normal;
  int? _schoolId;

  @override
  void initState() {
    super.initState();
    if (widget.schools.isNotEmpty) {
      _schoolId = widget.schools.first.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.forMoE
          ? 'New ministry announcement'
          : 'New school announcement'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.forMoE && widget.schools.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _schoolId,
                  decoration: const InputDecoration(labelText: 'School'),
                  items: [
                    for (final s in widget.schools)
                      DropdownMenuItem(value: s.id, child: Text(s.schoolName)),
                  ],
                  onChanged: (v) => setState(() => _schoolId = v),
                ),
              const SizedBox(height: 8),
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
                onChanged: (v) =>
                    setState(() => _urgency = v ?? _urgency),
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
              schoolId: widget.forMoE ? null : _schoolId,
            ));
          },
          child: const Text('Publish'),
        ),
      ],
    );
  }
}
