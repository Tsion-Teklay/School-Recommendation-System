// DTOs for `/api/forum`. Mirrors the Prisma `DiscussionForum` model.
//
// Two-level model: top-level posts have `threadId == null`; replies point at
// a top-level post. The list endpoint (`GET /api/forum`) only returns
// top-level posts; the detail endpoint (`GET /api/forum/:id`) returns the
// post plus its replies.

import '../../auth/data/auth_dtos.dart';

class ForumAuthor {
  final int id;
  final String fullName;
  final UserRole role;

  const ForumAuthor({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory ForumAuthor.fromJson(Map<String, dynamic> json) => ForumAuthor(
        id: (json['id'] as num).toInt(),
        fullName: (json['fullName'] ?? '?') as String,
        role: UserRoleX.fromWire(json['role'] as String),
      );
}

class ForumPost {
  final int id;
  final int authorId;
  final String content;
  final DateTime timestamp;
  final int? threadId;
  final bool isEdited;
  final ForumAuthor? author;

  /// Only present on list responses (`?listTopLevel`).
  final int? replyCount;

  /// Only present on the detail response.
  final List<ForumPost>? replies;

  const ForumPost({
    required this.id,
    required this.authorId,
    required this.content,
    required this.timestamp,
    required this.threadId,
    required this.isEdited,
    required this.author,
    required this.replyCount,
    required this.replies,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    int? parseIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    final authorJson = (json['author'] as Map?)?.cast<String, dynamic>();
    final repliesJson = json['replies'] as List?;
    return ForumPost(
      id: parseInt(json['id']),
      authorId: parseInt(json['authorId']),
      content: (json['content'] ?? '') as String,
      timestamp: parseDate(json['timestamp']),
      threadId: parseIntOrNull(json['threadId']),
      isEdited: (json['isEdited'] ?? false) as bool,
      author: authorJson != null ? ForumAuthor.fromJson(authorJson) : null,
      replyCount: parseIntOrNull(json['replyCount']),
      replies: repliesJson
          ?.cast<Map<String, dynamic>>()
          .map(ForumPost.fromJson)
          .toList(),
    );
  }
}
