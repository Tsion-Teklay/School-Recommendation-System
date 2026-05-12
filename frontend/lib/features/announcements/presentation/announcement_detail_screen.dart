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

class _Body extends StatelessWidget {
  final Announcement announcement;
  const _Body({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = announcement;
    final image = a.imgUrl;

    // Note: Ensure you have access to ref here.
    // Since _Body is currently a StatelessWidget, we should change it
    // to a ConsumerWidget to use 'ref.read'.
    return Consumer(
      builder: (context, ref, child) {
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

                    // --- NEW COMMENT SECTION START ---
                    const SizedBox(height: 32),
                    Text('Comments', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      // We use ref.read here to fetch the comments
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
                        if (comments.isEmpty)
                          return const Text('No comments yet');

                        return Column(
                          children: comments
                              .map((c) => CommentTile(comment: c))
                              .toList(),
                        );
                      },
                    ),
                    // --- NEW COMMENT SECTION END ---
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _absoluteImage(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
  return '${AppConfig.apiBaseUrl}/$url';
}
