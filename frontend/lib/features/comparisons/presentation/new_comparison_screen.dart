import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/responsive_shell.dart';
import '../../../shared/widgets/school_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../schools/state/compare_cart.dart';
import '../state/comparisons_controller.dart';

/// `/compare/new` — confirm the schools currently in the compare cart and
/// POST a new comparison. The cart is the source of truth; if it's empty we
/// nudge the user back to /schools.
class NewComparisonScreen extends ConsumerStatefulWidget {
  const NewComparisonScreen({super.key});
  @override
  ConsumerState<NewComparisonScreen> createState() =>
      _NewComparisonScreenState();
}

class _NewComparisonScreenState extends ConsumerState<NewComparisonScreen> {
  bool _busy = false;

  Future<void> _save() async {
    final cart = ref.read(compareCartProvider);
    if (!cart.canCreateComparison) return;
    final ids = cart.items.map((s) => s.id).toList();
    setState(() => _busy = true);
    try {
      final created =
          await ref.read(comparisonsControllerProvider).create(ids);
      if (!mounted) return;
      cart.clear();
      // We immediately navigate to the saved comparison so the user sees the
      // side-by-side rendering right away.
      context.go('/compare/${created.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(compareCartProvider);
    final theme = Theme.of(context);
    return ResponsiveShell(
      title: 'New comparison',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick 2–5 schools from the browse list, then save them as a '
            'comparison. You currently have ${cart.length} school'
            '${cart.length == 1 ? '' : 's'} in the compare cart.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (cart.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Compare cart is empty.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/schools'),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse schools'),
                  ),
                ],
              ),
            )
          else ...[
            ...cart.items.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SchoolCard(
                  school: s,
                  onTap: () => context.go('/schools/${s.id}'),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close),
                    onPressed: () => cart.remove(s.id),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!cart.canCreateComparison)
              Text(
                cart.length < CompareCart.minItems
                    ? 'Add ${CompareCart.minItems - cart.length} more '
                        'school${CompareCart.minItems - cart.length == 1 ? '' : 's'} '
                        'to save a comparison.'
                    : 'Comparisons support at most ${CompareCart.maxItems} '
                        'schools — remove some to continue.',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: cart.items.isEmpty ? null : cart.clear,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear cart'),
                ),
                LoadingButton(
                  loading: _busy,
                  onPressed: cart.canCreateComparison && !_busy ? _save : null,
                  child: const Text('Save comparison'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
