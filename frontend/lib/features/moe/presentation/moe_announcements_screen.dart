import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../admin/presentation/admin_announcements_screen.dart';
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
    final result = await showDialog<AnnouncementComposeResult>(
      context: context,
      builder: (_) => const AnnouncementComposeDialog(
        schools: [],
        forMoE: true,
      ),
    );
    if (result == null) return;
    try {
      final repo = ref.read(announcementRepositoryProvider);
      final created = await repo.createForMoe(result.input);
      // Phase 11 — attach the optional banner image after creation.
      if (result.image != null) {
        await repo.uploadImage(
          id: created.id,
          filename: result.image!.filename,
          bytes: result.image!.bytes,
        );
      }
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

// Phase 11: the dedicated MoE compose dialog was retired in favor of the
// shared `AnnouncementComposeDialog` (forMoE=true) so the image-attachment
// path is identical across roles.
