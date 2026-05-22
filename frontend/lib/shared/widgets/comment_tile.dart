import 'package:flutter/material.dart';
import '../../features/announcements/data/comment_dtos.dart';
import '../../features/likes/data/like_dtos.dart';
import '../../features/reports/data/report_dtos.dart';
import 'like_action.dart';
import 'report_dialog.dart';
import 'share_action.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  
  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        _formatDate(comment.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                LikeAction(
                    targetType: LikeTargetType.forumPost,
                    targetId: comment.id),
                ShareAction(
                  title: 'Comment by ${comment.authorName}',
                  content: comment.content,
                  url: 'https://yourapp.com/forum/${comment.id}',
                ),
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 20),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ReportDialog(
                      targetType: ReportTargetType.forumPost,
                      targetId: comment.id,
                    ),
                  ),
                  tooltip: 'Report',
                ),
              ],
            ),
            if (comment.replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...comment.replies.map((reply) => Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: CommentTile(comment: reply),
              )),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
