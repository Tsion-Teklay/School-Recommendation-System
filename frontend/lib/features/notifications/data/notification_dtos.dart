// DTOs for `/api/notifications`. Mirrors the Prisma `Notification` model
// (see backend/prisma/schema.prisma). The backend response shape is
// `{ message, data: [...], meta: {...} }`.

enum NotificationSourceType {
  announcement,
  report,
  review,
  school,
  system,
  forumPost,
  moderation,
}

extension NotificationSourceTypeX on NotificationSourceType {
  String label() {
    switch (this) {
      case NotificationSourceType.announcement:
        return 'Announcement';
      case NotificationSourceType.report:
        return 'Report';
      case NotificationSourceType.review:
        return 'Review';
      case NotificationSourceType.school:
        return 'School';
      case NotificationSourceType.system:
        return 'System';
      case NotificationSourceType.forumPost:
        return 'Forum';
      case NotificationSourceType.moderation:
        return 'Moderation';
    }
  }

  static NotificationSourceType fromWire(String? s) {
    switch (s) {
      case 'ANNOUNCEMENT':
        return NotificationSourceType.announcement;
      case 'REPORT':
        return NotificationSourceType.report;
      case 'REVIEW':
        return NotificationSourceType.review;
      case 'SCHOOL':
        return NotificationSourceType.school;
      case 'FORUM_POST':
        return NotificationSourceType.forumPost;
      case 'MODERATION':
        return NotificationSourceType.moderation;
      case 'SYSTEM':
      default:
        return NotificationSourceType.system;
    }
  }
}

class AppNotification {
  final int id;
  final String message;
  final NotificationSourceType sourceType;
  final int? sourceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.message,
    required this.sourceType,
    required this.sourceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
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
    return AppNotification(
      id: parseInt(json['id']),
      message: (json['message'] ?? '') as String,
      sourceType:
          NotificationSourceTypeX.fromWire(json['sourceType'] as String?),
      sourceId: parseIntOrNull(json['sourceId']),
      isRead: (json['isRead'] ?? false) as bool,
      createdAt: parseDate(json['createdAt']),
    );
  }

  AppNotification markedRead() => AppNotification(
        id: id,
        message: message,
        sourceType: sourceType,
        sourceId: sourceId,
        isRead: true,
        createdAt: createdAt,
      );
}
