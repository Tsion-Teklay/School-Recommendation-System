import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../data/announcement_dtos.dart';
import '../state/announcements_feed_controller.dart';
import '../../auth/state/auth_controller.dart';
import '../../auth/data/auth_dtos.dart';

/// `/announcements` — public list of school + ministry announcements.
/// Parents get an additional "Followed schools only" toggle that bumps
/// the backend's `followedOnly=true` filter on; non-parents always see
/// every visible announcement.
class AnnouncementsFeedScreen extends ConsumerStatefulWidget {
  const AnnouncementsFeedScreen({super.key});

  @override
  ConsumerState<AnnouncementsFeedScreen> createState() =>
      _AnnouncementsFeedScreenState();
}

class _AnnouncementsFeedScreenState
    extends ConsumerState<AnnouncementsFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementsFeedControllerProvider).ensureLoaded();
    });
  }

  bool _onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (m.maxScrollExtent > 0 && m.pixels >= m.maxScrollExtent - 200) {
      ref.read(announcementsFeedControllerProvider).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ctl = ref.watch(announcementsFeedControllerProvider);
    final theme = Theme.of(context);

    return ResponsiveShell(
      title: 'Announcements',
      onScrollNotification: _onScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltersBar(controller: ctl),
          const SizedBox(height: 16),
          if (ctl.error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ctl.error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: ctl.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (ctl.loading && ctl.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ctl.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No announcements to show.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ctl.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = ctl.items[i];
                return AnnouncementCard(
                  announcement: a,
                  onTap: () => context.go('/announcements/${a.id}'),
                );
              },
            ),
          if (ctl.appending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!ctl.loading && !ctl.appending && ctl.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: ctl.loadMore,
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  final AnnouncementsFeedController controller;
  const _FiltersBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (controller.canFollowedOnly)
              FilterChip(
                label: const Text('Followed schools only'),
                selected: controller.followedOnly,
                onSelected: (v) => controller.applyFilters(followedOnly: v),
              ),
            FilterChip(
              label: Text(controller.category?.label() ?? 'Any category'),
              selected: controller.category != null,
              onSelected: (v) {
                if (v) {
                  _showCategoryDialog(context, controller);
                } else {
                  controller.applyFilters(category: null);
                }
              },
            ),
            FilterChip(
              label: Text(controller.urgency?.label() ?? 'Any urgency'),
              selected: controller.urgency != null,
              onSelected: (v) {
                if (v) {
                  _showUrgencyDialog(context, controller);
                } else {
                  controller.applyFilters(urgency: null);
                }
              },
            ),
            FilterChip(
              label: Text(controller.publisherType?.label() ?? 'Any source'),
              selected: controller.publisherType != null,
              onSelected: (v) {
                if (v) {
                  _showPublisherTypeDialog(context, controller);
                } else {
                  controller.applyFilters(publisherType: null);
                }
              },
            ),
            TextButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable card to render one announcement summary. Used by both the
/// feed and the recent-announcements section on a school detail page.
class AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;
  final VoidCallback? onTap;
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = announcement;
    final image = a.imgUrl;
    final user = ref.watch(authControllerProvider).user;
                     
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null && image.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 7,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(a.datePosted),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(a.category.label()),
                      ),
                      if (a.urgencyLevel != UrgencyLevel.normal)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(a.urgencyLevel.label()),
                          backgroundColor:
                              a.urgencyLevel == UrgencyLevel.emergency
                                  ? theme.colorScheme.errorContainer
                                  : theme.colorScheme.tertiaryContainer,
                        ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          a.publisherType == PublisherType.moe
                              ? Icons.account_balance_outlined
                              : Icons.school_outlined,
                          size: 16,
                        ),
                        label: Text(
                            a.school?.schoolName ?? a.publisherType.label()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void _showCategoryDialog(BuildContext context, AnnouncementsFeedController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Any category'),
            onTap: () {
              controller.applyFilters(category: null);
              Navigator.pop(context);
            },
          ),
          ...AnnouncementCategory.values.map((category) => ListTile(
            title: Text(category.label()),
            onTap: () {
              controller.applyFilters(category: category);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    ),
  );
}

void _showUrgencyDialog(BuildContext context, AnnouncementsFeedController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Urgency'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Any urgency'),
            onTap: () {
              controller.applyFilters(urgency: null);
              Navigator.pop(context);
            },
          ),
          ...UrgencyLevel.values.map((urgency) => ListTile(
            title: Text(urgency.label()),
            onTap: () {
              controller.applyFilters(urgency: urgency);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    ),
  );
}

void _showPublisherTypeDialog(BuildContext context, AnnouncementsFeedController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Source'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Any source'),
            onTap: () {
              controller.applyFilters(publisherType: null);
              Navigator.pop(context);
            },
          ),
          ...PublisherType.values.map((type) => ListTile(
            title: Text(type.label()),
            onTap: () {
              controller.applyFilters(publisherType: type);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    ),
  );
}
