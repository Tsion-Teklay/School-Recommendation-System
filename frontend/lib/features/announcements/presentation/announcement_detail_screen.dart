import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_repository.dart';
import '../data/announcement_dtos.dart';
import '../data/announcement_repository.dart';

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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(a.category.label())),
                    Chip(
                      label: Text(a.urgencyLevel.label()),
                      backgroundColor: a.urgencyLevel == UrgencyLevel.emergency
                          ? theme.colorScheme.errorContainer
                          : a.urgencyLevel == UrgencyLevel.high
                              ? theme.colorScheme.tertiaryContainer
                              : null,
                    ),
                    Chip(
                      avatar: Icon(
                        a.publisherType == PublisherType.moe
                            ? Icons.account_balance_outlined
                            : Icons.school_outlined,
                        size: 16,
                      ),
                      label: Text(a.school?.schoolName ??
                          a.publisherType.label()),
                    ),
                    Text(
                      _formatDate(a.datePosted),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
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

String _formatDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
