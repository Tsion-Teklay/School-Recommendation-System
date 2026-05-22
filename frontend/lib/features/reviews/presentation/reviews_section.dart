import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../data/review_dtos.dart';
import '../state/reviews_controller.dart';

/// Read-by-everyone, write-by-PARENT reviews block. Embedded under the
/// school detail body so it inherits the outer ResponsiveShell scroll.
class ReviewsSection extends ConsumerStatefulWidget {
  final int schoolId;
  final VoidCallback? onReviewSubmitted;
  const ReviewsSection({super.key, required this.schoolId, this.onReviewSubmitted});

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reviewsControllerProvider(widget.schoolId).notifier)
          .ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller =
        ref.watch(reviewsControllerProvider(widget.schoolId));
    final auth = ref.watch(authControllerProvider);
    final isParent = auth.user?.role == UserRole.parent;
    final myReview = isParent
        ? controller.items.where((r) => r.parentId == auth.user?.id).cast<Review?>().firstOrNull
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Reviews', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (controller.initialized)
                  Text('${controller.items.length}',
                      style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (isParent)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _openForm(myReview),
                  icon: Icon(myReview == null ? Icons.add : Icons.edit),
                  label: Text(
                    myReview == null ? 'Write a review' : 'Edit my review',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (controller.loading && controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  controller.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
            else if (controller.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No reviews yet.'),
              )
            else
              Column(
                children: [
                  for (final r in controller.items)
                    _ReviewTile(
                      review: r,
                      mine: r.parentId == auth.user?.id && isParent,
                      onEdit: () => _openForm(r),
                      onDelete: () => _confirmDelete(r),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(Review? existing) async {
    final result = await showDialog<ReviewInput>(
      context: context,
      builder: (_) => _ReviewFormDialog(initial: existing),
    );
    if (result == null) return;
    final controller =
        ref.read(reviewsControllerProvider(widget.schoolId).notifier);
    final ok = existing == null
        ? await controller.create(result)
        : await controller.update(existing.id, result);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to save review')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved')),
      );
      widget.onReviewSubmitted?.call();
    }
  }

  Future<void> _confirmDelete(Review r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
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
    if (confirmed != true) return;
    final controller =
        ref.read(reviewsControllerProvider(widget.schoolId).notifier);
    await controller.remove(r.id);
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final bool mine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ReviewTile({
    required this.review,
    required this.mine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(
                  (review.parentFullName ?? '?')
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
                    Text(review.parentFullName ?? 'Parent',
                        style: theme.textTheme.titleSmall),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: theme.colorScheme.tertiary,
                            size: 16,
                          ),
                        const SizedBox(width: 8),
                        Text(review.categoryTag.label(),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              if (mine)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          if (review.comment?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 52),
              child: Text(review.comment!),
            ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _ReviewFormDialog extends StatefulWidget {
  final Review? initial;
  const _ReviewFormDialog({required this.initial});

  @override
  State<_ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<_ReviewFormDialog> {
  late int _rating;
  late ReviewCategoryTag _tag;
  late TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _rating = widget.initial?.rating ?? 5;
    _tag = widget.initial?.categoryTag ?? ReviewCategoryTag.teachingQuality;
    _commentCtrl =
        TextEditingController(text: widget.initial?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.initial == null ? 'Write a review' : 'Edit review'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating', style: theme.textTheme.titleSmall),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReviewCategoryTag>(
              value: _tag,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final t in ReviewCategoryTag.values)
                  DropdownMenuItem(value: t, child: Text(t.label())),
              ],
              onChanged: (v) => setState(() => _tag = v ?? _tag),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience…',
              ),
              minLines: 2,
              maxLines: 5,
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
          onPressed: () => Navigator.of(context).pop(
            ReviewInput(
              rating: _rating,
              comment: _commentCtrl.text.trim().isEmpty
                  ? null
                  : _commentCtrl.text.trim(),
              categoryTag: _tag,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
