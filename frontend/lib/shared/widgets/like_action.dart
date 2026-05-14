import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/likes/data/like_dtos.dart';
import '../../features/likes/state/like_controller.dart';

class LikeAction extends ConsumerWidget {
  final LikeTargetType targetType;
  final int targetId;
  const LikeAction(
      {super.key, required this.targetType, required this.targetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.watch(likeControllerProvider);
    final isLiked = ctl.isLiked(targetType, targetId);

    return IconButton(
      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
      color: isLiked ? Colors.red : null,
      onPressed: () =>
          ref.read(likeControllerProvider).toggleLike(targetType, targetId),
      tooltip: 'Like',
    );
  }
}
