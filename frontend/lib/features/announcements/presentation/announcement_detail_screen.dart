import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../data/announcement_dtos.dart';
import '../data/announcement_repository.dart';

import '../../../shared/widgets/like_action.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/share_action.dart';
import '../../../shared/widgets/comment_tile.dart';
import '../../../features/reports/data/report_dtos.dart';
import '../../../features/likes/data/like_dtos.dart';

/// `/announcements/:id` — single announcement view. Loaded on demand so
/// deep links from notifications work without first hitting the list.
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final int announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  bool _loading = true;
  String? _error;
  Announcement? _item;

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
      final item = await ref
          .read(announcementRepositoryProvider)
          .getById(widget.announcementId);
      if (!mounted) return;
      setState(() => _item = item);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = _item;
    return ResponsiveShell(
      title: a?.title ?? 'Announcement',
      leading: BackButton(onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/announcements');
        }
      }),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!)),
                        TextButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : a == null
                  ? const SizedBox.shrink()
                  : _Body(announcement: a),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Announcement announcement;
  const _Body({required this.announcement});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _commentCtrl = TextEditingController();
  bool _posting = false;
  int _commentRefreshKey = 0;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .postAnnouncementComment(widget.announcement.id, text);
      _commentCtrl.clear();
      // Bump the key to force FutureBuilder to refetch.
      setState(() => _commentRefreshKey++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.announcement;
    final image = a.imgUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null && image.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                _absoluteImage(image),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                      child: Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: theme.textTheme.headlineSmall),
                // ... (Chips and Content section remains the same)
                const SizedBox(height: 16),
                SelectableText(
                  a.content,
                  style: theme.textTheme.bodyLarge,
                ),
                if (a.school != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () =>
                        GoRouter.of(context).go('/schools/${a.school!.id}'),
                    icon: const Icon(Icons.open_in_new),
                    label: Text('View ${a.school!.schoolName}'),
                  ),
                ],

                // --- ACTION BAR ---
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LikeAction(
                        targetType: LikeTargetType.announcement,
                        targetId: a.id),
                    ShareAction(
                      title: a.title,
                      content: a.content,
                      url: 'https://yourapp.com/announcements/${a.id}',
                    ),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => ReportDialog(
                          targetType: ReportTargetType.announcement,
                          targetId: a.id,
                        ),
                      ),
                      tooltip: 'Report',
                    ),
                  ],
                ),

                // --- COMMENT SECTION ---
                const SizedBox(height: 32),
                Text('Comments', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),

                // Comment input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                            hintText: 'Share your thoughts...',
                          ),
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _posting ? null : _postComment,
                            icon: _posting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Comment'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Comments list
                FutureBuilder(
                  key: ValueKey(_commentRefreshKey),
                  future: ref
                      .read(announcementRepositoryProvider)
                      .getAnnouncementComments(a.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                          'Error loading comments: ${snapshot.error}');
                    }

                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Text('No comments yet. Be the first to comment!');
                    }

                    return Column(
                      children: comments
                          .map((c) => CommentTile(comment: c))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _absoluteImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
  return '${AppConfig.apiBaseUrl}/$url';
}
