import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../analytics/data/analytics_dtos.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../auth/data/auth_repository.dart';

class MoeDashboardScreen extends ConsumerStatefulWidget {
  const MoeDashboardScreen({super.key});

  @override
  ConsumerState<MoeDashboardScreen> createState() =>
      _MoeDashboardScreenState();
}

class _MoeDashboardScreenState extends ConsumerState<MoeDashboardScreen> {
  bool _loading = false;
  String? _error;
  Dashboard? _dashboard;

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
      final d = await ref.read(analyticsRepositoryProvider).dashboard();
      setState(() => _dashboard = d);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pulls the CSV bytes and copies them to the system clipboard. We
  /// deliberately keep this simple (clipboard) instead of pulling in a
  /// platform-conditional download library — the MoE officer can paste the
  /// payload into a `.csv` file in seconds, and the UX is identical on web,
  /// Android, and iOS.
  Future<void> _copyCsv() async {
    try {
      final csv =
          await ref.read(analyticsRepositoryProvider).dashboardCsv();
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copied — paste into a .csv file in Excel/Sheets.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = _dashboard;
    return ResponsiveShell(
      title: 'Ministry dashboard',
      child: _loading && d == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                )
              : d == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header uses Wrap instead of Row+Spacer so the
                        // trailing FilledButton.icon (Copy CSV) actually
                        // renders on Flutter web release builds.
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Overview',
                                style: theme.textTheme.headlineSmall),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Refresh',
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                ),
                                FilledButton.icon(
                                  onPressed: _copyCsv,
                                  icon: const Icon(Icons.download),
                                  label: const Text('Copy CSV'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _SummaryGrid(summary: d.summary),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (ctx, c) {
                            final wide = c.maxWidth > 800;
                            final cards = [
                              _BreakdownCard(
                                title: 'Users by role',
                                data: d.usersByRole,
                              ),
                              _BreakdownCard(
                                title: 'Schools by verification',
                                data: d.schoolsByVerification,
                              ),
                              _BreakdownCard(
                                title: 'Reports by status',
                                data: d.reportsByStatus,
                              ),
                            ];
                            if (wide) {
                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < cards.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 12),
                                    Expanded(child: cards[i]),
                                  ]
                                ],
                              );
                            }
                            return Column(children: cards);
                          },
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (ctx, c) {
                            final wide = c.maxWidth > 800;
                            final cards = [
                              _SchoolListCard(
                                title: 'Top schools by rating',
                                empty: 'No schools yet.',
                                children: [
                                  for (final s in d.topSchools)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(s.schoolName),
                                      subtitle: Text(
                                        '${s.rating.toStringAsFixed(1)} '
                                        '(${s.reviewCount} reviews) · '
                                        '${s.verificationStatus}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () =>
                                            context.go('/schools/${s.id}'),
                                      ),
                                    ),
                                ],
                              ),
                              _SchoolListCard(
                                title: 'Most followed schools',
                                empty: 'No followers yet.',
                                children: [
                                  for (final s in d.mostFollowed)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(s.schoolName ??
                                          'School #${s.schoolId}'),
                                      subtitle:
                                          Text('${s.followers} follower(s)'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () => context
                                            .go('/schools/${s.schoolId}'),
                                      ),
                                    ),
                                ],
                              ),
                            ];
                            if (wide) {
                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: cards[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: cards[1]),
                                ],
                              );
                            }
                            return Column(children: cards);
                          },
                        ),
                      ],
                    ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      ('Total users', summary.totalUsers),
      ('Total schools', summary.totalSchools),
      ('Total reviews', summary.totalReviews),
      ('Total announcements', summary.totalAnnouncements),
      ('Total reports', summary.totalReports),
      ('Forum posts', summary.totalForumPosts),
      ('Total follows', summary.totalFollows),
      ('Avg. rating', summary.averageRating.toStringAsFixed(2)),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth > 1100
            ? 4
            : c.maxWidth > 700
                ? 3
                : 2;
        final width = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in cards)
              SizedBox(
                width: width,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.$1, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text('${entry.$2}',
                            style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  const _BreakdownCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (data.isEmpty)
              const Text('No data.')
            else
              for (final entry in data.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value}'),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SchoolListCard extends StatelessWidget {
  final String title;
  final String empty;
  final List<Widget> children;
  const _SchoolListCard({
    required this.title,
    required this.empty,
    required this.children,
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
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (children.isEmpty) Text(empty) else ...children,
          ],
        ),
      ),
    );
  }
}
