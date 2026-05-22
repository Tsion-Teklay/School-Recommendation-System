import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/school_card.dart';
import '../../auth/state/auth_controller.dart';
import '../../schools/state/compare_cart.dart';
import '../state/recommendations_controller.dart';
import '../../schools/data/school_repository.dart';

/// Parent home — `GET /api/recommendations` ranked schools with the score
/// breakdown surfaced under each card. The breakdown is what differentiates
/// this view from the plain `/schools` browse list.
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.watch(recommendationsControllerProvider);
    final state = ctl.state;
    final user = ref.watch(authControllerProvider).user;
    final cart = ref.watch(compareCartProvider);

    return ResponsiveShell(
      title: 'Recommended for you',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ctl.refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: cart.length >= CompareCart.minItems
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/compare/new'),
              icon: const Icon(Icons.compare_arrows),
              label: Text('Compare ${cart.length}'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Text('Welcome, ${user.fullName}',
                style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Schools ranked using your stored preferences (curriculum, '
            'budget, location, and rating). Tap a school to see details, or '
            'add 2–5 to the compare cart.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (state.criteria.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CriteriaSummary(criteria: state.criteria),
          ],
          const SizedBox(height: 16),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            _ErrorBlock(message: state.error!, onRetry: () => ctl.refresh())
          else if (state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No recommendations yet.\nTry browsing schools to seed '
                  'your preferences.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = state.items[i];
                final inCart = cart.contains(r.school.id);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SchoolCard(
                      school: r.school,
                      onTap: () async {
                        // Navigate to detail
                        context.go(
                            '/schools/${r.school.id}?recommendationId=${state.historyId}');

                        // Send feedback (fire-and-forget)
                        if (state.historyId != null) {
                          try {
                            print("historyId: ${state.historyId}");
                            ref
                                .read(schoolRepositoryProvider)
                                .sendRecommendationFeedback(
                                  historyId: state.historyId!,
                                  result: 'OPENED',
                                  schoolId: r.school.id,
                                );
                          } catch (e) {
                            // Log error silently to not block UI
                          }
                        }
                      },
                      trailing: IconButton(
                        tooltip:
                            inCart ? 'Remove from compare' : 'Add to compare',
                        icon: Icon(
                          inCart
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: inCart
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onPressed: () {
                          if (inCart) {
                            cart.remove(r.school.id);
                          } else if (!cart.add(r.school)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Compare cart is full (max 5).')),
                            );
                          }
                        },
                      ),
                    ),
                    if (r.breakdown.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: _BreakdownRow(
                          score: r.score,
                          breakdown: r.breakdown,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CriteriaSummary extends StatelessWidget {
  final Map<String, dynamic> criteria;
  const _CriteriaSummary({required this.criteria});

  @override
  Widget build(BuildContext context) {
    final entries = <String>[];
    void add(String key, String label) {
      final v = criteria[key];
      if (v != null && v.toString().isNotEmpty) entries.add('$label: $v');
    }

    add('curriculum', 'curriculum');
    add('max_budget', 'max budget');
    add('min_budget', 'min budget');
    add('lat', 'lat');
    add('lng', 'lng');

    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Using ${entries.join(' · ')}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final num score;
  final Map<String, num> breakdown;
  const _BreakdownRow({required this.score, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = breakdown.entries.toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'score ${score.toStringAsFixed(1)}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onPrimary),
          ),
        ),
        ...entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${e.key} ${e.value.toStringAsFixed(1)}',
              style: theme.textTheme.labelSmall,
            ),
          );
        }),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
