import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../data/forum_dtos.dart';
import '../state/forum_detail_controller.dart';

class ForumDetailScreen extends ConsumerStatefulWidget {
  final int postId;
  const ForumDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ForumDetailScreen> createState() =>
      _ForumDetailScreenState();
}

class _ForumDetailScreenState extends ConsumerState<ForumDetailScreen> {
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(forumDetailControllerProvider(widget.postId).notifier)
          .ensureLoaded();
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        ref.watch(forumDetailControllerProvider(widget.postId));
    final me = ref.watch(authControllerProvider).user;
    final post = controller.post;

    return ResponsiveShell(
      title: 'Forum post',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.loading && post == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(controller.error!),
              ),
            )
          else if (post == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Post not found.')),
            )
          else ...[
            _PostBody(
              post: post,
              isMine: post.authorId == me?.id,
              isModerator: me != null && me.role.toWire() == 'MODERATOR',
              onEdit: () => _editPost(post),
              onDelete: () => _deletePost(post),
            ),
            const SizedBox(height: 16),
            Text('Replies', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if ((post.replies ?? []).isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No replies yet.'),
              )
            else
              for (final r in post.replies!)
                _PostBody(
                  post: r,
                  isMine: r.authorId == me?.id,
                  isModerator:
                      me != null && me.role.toWire() == 'MODERATOR',
                  onEdit: () => _editPost(r),
                  onDelete: () => _deletePost(r),
                  isReply: true,
                ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _replyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add a reply',
                      ),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: controller.saving
                            ? null
                            : () => _sendReply(controller),
                        icon: const Icon(Icons.send),
                        label: const Text('Reply'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendReply(ForumDetailController controller) async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    final ok = await controller.reply(text);
    if (!mounted) return;
    if (ok) {
      _replyCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to reply')),
      );
    }
  }

  Future<void> _editPost(ForumPost post) async {
    final controller = ref.read(forumDetailControllerProvider(widget.postId).notifier);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(initial: post.content),
    );
    if (result == null || result.trim().isEmpty) return;
    final ok = await controller.updateBody(post.id, result.trim());
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to update')),
      );
    }
  }

  Future<void> _deletePost(ForumPost post) async {
    final controller = ref.read(forumDetailControllerProvider(widget.postId).notifier);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
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
    final ok = await controller.remove(post.id);
    if (!mounted) return;
    if (ok && post.id == widget.postId) {
      context.go('/forum');
    } else if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to delete')),
      );
    }
  }
}

class _PostBody extends StatelessWidget {
  final ForumPost post;
  final bool isMine;
  final bool isModerator;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isReply;
  const _PostBody({
    required this.post,
    required this.isMine,
    required this.isModerator,
    required this.onEdit,
    required this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 24 : 0, bottom: 8),
      child: Card(
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
                          '${post.author?.role.label() ?? ''} · '
                          '${post.timestamp.toIso8601String().substring(0, 16).replaceAll("T", " ")}'
                          '${post.isEdited ? ' · edited' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isMine || isModerator)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit' && isMine) onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        if (isMine)
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.content),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final String initial;
  const _EditDialog({required this.initial});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit post'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
            child: const Text('Save')),
      ],
    );
  }
}
