import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/responsive_shell.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/state/auth_controller.dart';
import '../data/review_dtos.dart';
import '../state/reviews_controller.dart';

/// `/schools/:schoolId/reviews` — dedicated page showing all reviews for a specific school
/// with pagination support.
class SchoolReviewsScreen extends ConsumerStatefulWidget {
  final int schoolId;
  const SchoolReviewsScreen({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolReviewsScreen> createState() =>
      _SchoolReviewsScreenState();
}

class _SchoolReviewsScreenState extends ConsumerState<SchoolReviewsScreen> {
  bool _showForm = false;
  int _rating = 5;
  ReviewCategoryTag _tag = ReviewCategoryTag.teachingQuality;
  TextEditingController _commentCtrl = TextEditingController();
  Review? _editingReview;

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
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final m = n.metrics;
    if (m.maxScrollExtent > 0 && m.pixels >= m.maxScrollExtent - 200) {
      ref.read(reviewsControllerProvider(widget.schoolId).notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        ref.watch(reviewsControllerProvider(widget.schoolId));
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final isParent = auth.user?.role == UserRole.parent;

    return ResponsiveShell(
      title: 'All Reviews',
      onScrollNotification: _onScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isParent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_showForm)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: controller.saving
                            ? null
                            : () => _toggleForm(null),
                        icon: const Icon(Icons.add),
                        label: const Text('Write a review'),
                      ),
                    ),
                  if (_showForm && _editingReview == null)
                    _ReviewForm(
                      rating: _rating,
                      tag: _tag,
                      commentCtrl: _commentCtrl,
                      onRatingChanged: (v) => setState(() => _rating = v),
                      onTagChanged: (v) => setState(() => _tag = v),
                      onSave: _saveReview,
                      onCancel: () => setState(() {
                        _showForm = false;
                        _commentCtrl.clear();
                        _rating = 5;
                        _tag = ReviewCategoryTag.teachingQuality;
                        _editingReview = null;
                      }),
                      saving: controller.saving,
                    ),
                ],
              ),
            ),
          if (controller.error != null)
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
                        controller.error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (controller.loading && controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No reviews yet.')),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final r in controller.items)
                    if (_editingReview?.id == r.id && _showForm)
                      _ReviewForm(
                        rating: _rating,
                        tag: _tag,
                        commentCtrl: _commentCtrl,
                        onRatingChanged: (v) => setState(() => _rating = v),
                        onTagChanged: (v) => setState(() => _tag = v),
                        onSave: _saveReview,
                        onCancel: () => setState(() {
                          _showForm = false;
                          _commentCtrl.clear();
                          _rating = 5;
                          _tag = ReviewCategoryTag.teachingQuality;
                          _editingReview = null;
                        }),
                        saving: controller.saving,
                      )
                    else
                      _ReviewTile(
                        review: r,
                        mine: r.parentId == auth.user?.id && isParent,
                        onEdit: () => _toggleForm(r),
                        onDelete: () => _confirmDelete(r),
                      ),
                ],
              ),
            ),
          if (controller.appending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!controller.loading &&
              !controller.appending &&
              controller.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: () =>
                      ref.read(reviewsControllerProvider(widget.schoolId).notifier).loadMore(),
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleForm(Review? existing) {
    setState(() {
      final isSameReview = _editingReview != null && 
                          existing != null && 
                          _editingReview!.id == existing.id;
      
      if (_showForm && isSameReview) {
        // Toggle off if clicking the same review
        _showForm = false;
        _commentCtrl.clear();
        _rating = 5;
        _tag = ReviewCategoryTag.teachingQuality;
        _editingReview = null;
      } else {
        // Show form for new or different review
        _showForm = true;
        _editingReview = existing;
        if (existing != null) {
          _rating = existing.rating;
          _tag = existing.categoryTag;
          _commentCtrl.text = existing.comment ?? '';
        } else {
          _rating = 5;
          _tag = ReviewCategoryTag.teachingQuality;
          _commentCtrl.clear();
        }
      }
    });
  }

  Future<void> _saveReview() async {
    final controller =
        ref.read(reviewsControllerProvider(widget.schoolId).notifier);
    final input = ReviewInput(
      rating: _rating,
      comment: _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim(),
      categoryTag: _tag,
    );
    
    final ok = _editingReview == null
        ? await controller.create(input)
        : await controller.update(_editingReview!.id, input);
    
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Failed to save review')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved')),
      );
      setState(() {
        _showForm = false;
        _commentCtrl.clear();
        _rating = 5;
        _tag = ReviewCategoryTag.teachingQuality;
        _editingReview = null;
      });
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                if (mine) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outlined),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
            if (review.comment?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 52),
                child: Text(review.comment!),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final int rating;
  final ReviewCategoryTag tag;
  final TextEditingController commentCtrl;
  final Function(int) onRatingChanged;
  final Function(ReviewCategoryTag) onTagChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool saving;

  const _ReviewForm({
    required this.rating,
    required this.tag,
    required this.commentCtrl,
    required this.onRatingChanged,
    required this.onTagChanged,
    required this.onSave,
    required this.onCancel,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating', style: theme.textTheme.titleSmall),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => onRatingChanged(i),
                    icon: Icon(
                      i <= rating ? Icons.star : Icons.star_border,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReviewCategoryTag>(
              value: tag,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final t in ReviewCategoryTag.values)
                  DropdownMenuItem(value: t, child: Text(t.label())),
              ],
              onChanged: (v) => onTagChanged(v ?? tag),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience…',
              ),
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}