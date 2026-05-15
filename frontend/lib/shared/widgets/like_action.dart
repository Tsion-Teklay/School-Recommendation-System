import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/likes/data/like_dtos.dart';
import '../../features/likes/state/like_controller.dart';

class LikeAction extends ConsumerStatefulWidget {
  final LikeTargetType targetType;
  final int targetId;
  const LikeAction(
      {super.key, required this.targetType, required this.targetId});

  @override
  ConsumerState<LikeAction> createState() => _LikeActionState();
}

class _LikeActionState extends ConsumerState<LikeAction> {
  @override
  void initState() {
    super.initState();
    // Fetch initial like data (count + status) on first build.
    Future.microtask(() {
      ref
          .read(likeControllerProvider)
          .refreshLikeData(widget.targetType, widget.targetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctl = ref.watch(likeControllerProvider);
    final isLiked = ctl.isLiked(widget.targetType, widget.targetId);
    final count = ctl.getLikeCount(widget.targetType, widget.targetId);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => ref
          .read(likeControllerProvider)
          .toggleLike(widget.targetType, widget.targetId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
              size: 20,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLiked ? Colors.red : null,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
