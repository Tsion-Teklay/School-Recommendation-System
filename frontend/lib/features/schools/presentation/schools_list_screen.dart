import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../ads/presentation/ad_banner_section.dart';
import '../../ads/data/ad_dtos.dart';
import '../../../shared/widgets/school_card.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../data/school_dtos.dart';
import '../state/compare_cart.dart';
import '../state/schools_list_controller.dart';

/// `/schools` — paginated browse list with search + curriculum + fee filters.
/// Tapping a card pushes the detail screen; parents see an "Add to compare"
/// toggle on each card.
class SchoolsListScreen extends ConsumerStatefulWidget {
  const SchoolsListScreen({super.key});

  @override
  ConsumerState<SchoolsListScreen> createState() => _SchoolsListScreenState();
}

class _SchoolsListScreenState extends ConsumerState<SchoolsListScreen> {
  final _searchCtl = TextEditingController();
  final _minFeeCtl = TextEditingController();
  final _maxFeeCtl = TextEditingController();
  Curriculum? _curriculum;
  SchoolLevel? _schoolLevel;
  SchoolType? _schoolType;
  SubCity? _subCity;
  // Min rating, 1-5 scale. 0 means "no minimum".
  double _minRating = 0;

  @override
  void dispose() {
    _searchCtl.dispose();
    _minFeeCtl.dispose();
    _maxFeeCtl.dispose();
    super.dispose();
  }

  /// Auto-pagination hook. The outer scroll is owned by `ResponsiveShell`'s
  /// `SingleChildScrollView`, so a child-attached `ScrollController` would
  /// never fire — we listen for scroll notifications bubbling up instead.
  /// Returning `false` lets other listeners (and the underlying scrollable)
  /// see the same notification.
  bool _onScrollNotification(ScrollNotification n) {
    final m = n.metrics;
    if (m.maxScrollExtent > 0 && m.pixels >= m.maxScrollExtent - 200) {
      // `loadMore` no-ops when there's no next page or a fetch is in flight,
      // so we can spam this safely.
      ref.read(schoolsListControllerProvider).loadMore();
    }
    return false;
  }

  void _applyFilters() {
    final ctl = ref.read(schoolsListControllerProvider);
    ctl.applyFilters(SchoolListFilters(
      search: _searchCtl.text.trim().isEmpty ? null : _searchCtl.text.trim(),
      curriculum: _curriculum,
      minFee: num.tryParse(_minFeeCtl.text.trim()),
      maxFee: num.tryParse(_maxFeeCtl.text.trim()),
      minRating: _minRating > 0 ? _minRating : null,
      schoolLevel: _schoolLevel,
      schoolType: _schoolType,
      subCity: _subCity,
      // We deliberately don't carry `near` here — proximity search needs a
      // browser geolocation prompt which we'll wire as a separate IconButton
      // in a future iteration.
    ));
  }

  void _clearFilters() {
    _searchCtl.clear();
    _minFeeCtl.clear();
    _maxFeeCtl.clear();
    setState(() {
      _curriculum = null;
      _schoolLevel = null;
      _schoolType = null;
      _subCity = null;
      _minRating = 0;
    });
    ref
        .read(schoolsListControllerProvider)
        .applyFilters(const SchoolListFilters());
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Advanced Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('School Level'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: SchoolLevel.values.map((level) => 
                    ChoiceChip(
                      label: Text(level.label()),
                      selected: _schoolLevel == level,
                      onSelected: (selected) {
                        setState(() {
                          _schoolLevel = selected ? level : null;
                        });
                        setDialogState(() {});
                      },
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),
                const Text('School Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: SchoolType.values.map((type) => 
                    ChoiceChip(
                      label: Text(type.label()),
                      selected: _schoolType == type,
                      onSelected: (selected) {
                        setState(() {
                          _schoolType = selected ? type : null;
                        });
                        setDialogState(() {});
                      },
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Subcity'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SubCity.values.map((subcity) => 
                    ChoiceChip(
                      label: Text(subcity.label),
                      selected: _subCity == subcity,
                      onSelected: (selected) {
                        setState(() {
                          _subCity = selected ? subcity : null;
                        });
                        setDialogState(() {});
                      },
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolsListControllerProvider).state;
    final cart = ref.watch(compareCartProvider);
    final auth = ref.watch(authControllerProvider);
    final isParent = auth.user?.role == UserRole.parent;

    return ResponsiveShell(
      title: 'Browse schools',
      onScrollNotification: _onScrollNotification,
      floatingActionButton: isParent && cart.length >= CompareCart.minItems
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/compare/new'),
              icon: const Icon(Icons.compare_arrows),
              label: Text('Compare ${cart.length}'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Filters(
            searchCtl: _searchCtl,
            minFeeCtl: _minFeeCtl,
            maxFeeCtl: _maxFeeCtl,
            curriculum: _curriculum,
            minRating: _minRating,
            onCurriculumChanged: (c) => setState(() => _curriculum = c),
            onMinRatingChanged: (r) => setState(() => _minRating = r),
            onApply: _applyFilters,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 16),
          const AdBannerSection(
            placement: AdPlacementType.banner,
            limit: 1,
          ),
          const SizedBox(height: 16),
          if (state.error != null)
            _ErrorBanner(
              message: state.error!,
              onRetry: () =>
                  ref.read(schoolsListControllerProvider).refresh(),
            ),
          if (state.initialLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No schools match those filters.')),
            )
          else
            _SchoolList(
              items: state.items,
              loadingMore: state.loadingMore,
              hasMore: state.hasMore,
              isParent: isParent,
              cart: cart,
            ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchCtl;
  final TextEditingController minFeeCtl;
  final TextEditingController maxFeeCtl;
  final Curriculum? curriculum;
  final double minRating;
  final ValueChanged<Curriculum?> onCurriculumChanged;
  final ValueChanged<double> onMinRatingChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _Filters({
    required this.searchCtl,
    required this.minFeeCtl,
    required this.maxFeeCtl,
    required this.curriculum,
    required this.minRating,
    required this.onCurriculumChanged,
    required this.onMinRatingChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchCtl,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onApply(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Local'),
                  selected: curriculum == Curriculum.local,
                  onSelected: (_) => onCurriculumChanged(
                      curriculum == Curriculum.local
                          ? null
                          : Curriculum.local),
                ),
                ChoiceChip(
                  label: const Text('International'),
                  selected: curriculum == Curriculum.international,
                  onSelected: (_) => onCurriculumChanged(
                      curriculum == Curriculum.international
                          ? null
                          : Curriculum.international),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: minFeeCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: maxFeeCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Find the parent widget to call _showFilterDialog
                    final parentState = context.findAncestorStateOfType<_SchoolsListScreenState>();
                    parentState?._showFilterDialog();
                  },
                  icon: const Icon(Icons.tune),
                  tooltip: 'More filters',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Phase 11 — minimum rating slider. 0 disables the filter; 1–5
            // map to the same scale as Review.rating.
            Row(
              children: [
                const Text('Min rating'),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: minRating == 0
                        ? 'Any'
                        : minRating.toStringAsFixed(1),
                    onChanged: onMinRatingChanged,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    minRating == 0 ? 'Any' : minRating.toStringAsFixed(1),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolList extends ConsumerWidget {
  final List<School> items;
  final bool loadingMore;
  final bool hasMore;
  final bool isParent;
  final CompareCart cart;

  const _SchoolList({
    required this.items,
    required this.loadingMore,
    required this.hasMore,
    required this.isParent,
    required this.cart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length + (hasMore || loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i >= items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => ref
                          .read(schoolsListControllerProvider)
                          .loadMore(),
                      child: const Text('Load more'),
                    ),
            ),
          );
        }
        final school = items[i];
        Widget? trailing;
        if (isParent) {
          final inCart = cart.contains(school.id);
          trailing = IconButton(
            tooltip: inCart ? 'Remove from compare' : 'Add to compare',
            onPressed: () {
              final ok = inCart ? true : cart.add(school);
              if (inCart) {
                cart.remove(school.id);
              } else if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compare cart is full (max 5).'),
                  ),
                );
              }
            },
            icon: Icon(
              inCart ? Icons.check_box : Icons.check_box_outline_blank,
              color: inCart ? Theme.of(context).colorScheme.primary : null,
            ),
          );
        }
        return SchoolCard(
          school: school,
          onTap: () => context.go('/schools/${school.id}'),
          trailing: trailing,
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
