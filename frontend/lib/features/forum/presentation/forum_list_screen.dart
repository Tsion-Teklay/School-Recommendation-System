import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/like_action.dart';
import '../../../shared/widgets/share_action.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../auth/data/auth_dtos.dart';
import '../../likes/data/like_dtos.dart';
import '../../likes/state/like_controller.dart';
import '../data/forum_dtos.dart';
import '../state/forum_list_controller.dart';
import '../../reports/data/report_dtos.dart';

class ForumListScreen extends ConsumerStatefulWidget {
  const ForumListScreen({super.key});

  @override
  ConsumerState<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends ConsumerState<ForumListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumListControllerProvider).ensureLoaded();
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      ref.read(forumListControllerProvider).loadMore();
    }
    return false;
  }

  Future<void> _openCompose() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _ComposeDialog(title: 'New post'),
    );
    if (result == null || result.trim().isEmpty) return;
    final controller = ref.read(forumListControllerProvider);
    final ok = await controller.create(result.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(forumListControllerProvider);
    // Ensure controller is loaded when building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.initialized && !controller.loading) {
        controller.ensureLoaded();
      }
    });
    return ResponsiveShell(
      title: 'Forum',
      onScrollNotification: _onScroll,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCompose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New post'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(controller.error!),
              ),
            ),
          if (controller.loading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No posts yet. Start the discussion.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = controller.items[i];
                return _PostTile(post: p);
              },
            ),
          if (controller.appending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.hasMore && !controller.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: controller.loadMore,
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostTile extends ConsumerWidget {
  final ForumPost post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.go('/forum/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      (post.author?.fullName ?? '?')
                              .characters
                              .firstOrNull
                              ?.toUpperCase() ??
                          '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.author?.fullName ?? 'User',
                            style: theme.textTheme.titleSmall),
                        Text(
                          '${post.author?.role.label() ?? ''} · ${_formatDate(post.timestamp)}'
                          '${post.isEdited ? ' · edited' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if ((post.replyCount ?? 0) > 0)
                    Chip(
                      avatar: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: Text('${post.replyCount}'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.content),
              const SizedBox(height: 12),
              // Action bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LikeAction(
                    targetType: LikeTargetType.forumPost,
                    targetId: post.id,
                  ),
                  ShareAction(
                    title: post.content.length > 50
                        ? '${post.content.substring(0, 50)}...'
                        : post.content,
                    content: post.content,
                    url: 'https://yourapp.com/forum/${post.id}',
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ReportDialog(
                          targetType: ReportTargetType.forumPost,
                          targetId: post.id,
                        ),
                      );
                    },
                    tooltip: 'Report',
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

class _ComposeDialog extends StatefulWidget {
  final String title;
  const _ComposeDialog({required this.title});

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What do you want to discuss?',
          ),
          minLines: 3,
          maxLines: 8,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('Post'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
