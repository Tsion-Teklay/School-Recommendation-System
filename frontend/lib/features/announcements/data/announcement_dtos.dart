// DTOs for `/api/announcements/*`. Mirrors Prisma `Announcement`.

enum AnnouncementCategory { admissions, policy, fee, other }

extension AnnouncementCategoryX on AnnouncementCategory {
  String toWire() {
    switch (this) {
      case AnnouncementCategory.admissions:
        return 'ADMISSIONS';
      case AnnouncementCategory.policy:
        return 'POLICY';
      case AnnouncementCategory.fee:
        return 'FEE';
      case AnnouncementCategory.other:
        return 'OTHER';
    }
  }

  String label() {
    switch (this) {
      case AnnouncementCategory.admissions:
        return 'Admissions';
      case AnnouncementCategory.policy:
        return 'Policy';
      case AnnouncementCategory.fee:
        return 'Fee';
      case AnnouncementCategory.other:
        return 'Other';
    }
  }

  static AnnouncementCategory fromWire(String? s) {
    switch (s) {
      case 'ADMISSIONS':
        return AnnouncementCategory.admissions;
      case 'POLICY':
        return AnnouncementCategory.policy;
      case 'FEE':
        return AnnouncementCategory.fee;
      case 'OTHER':
      default:
        return AnnouncementCategory.other;
    }
  }
}

enum UrgencyLevel { normal, high, emergency }

extension UrgencyLevelX on UrgencyLevel {
  String toWire() {
    switch (this) {
      case UrgencyLevel.normal:
        return 'NORMAL';
      case UrgencyLevel.high:
        return 'HIGH';
      case UrgencyLevel.emergency:
        return 'EMERGENCY';
    }
  }

  String label() {
    switch (this) {
      case UrgencyLevel.normal:
        return 'Normal';
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.emergency:
        return 'Emergency';
    }
  }

  static UrgencyLevel fromWire(String? s) {
    switch (s) {
      case 'HIGH':
        return UrgencyLevel.high;
      case 'EMERGENCY':
        return UrgencyLevel.emergency;
      case 'NORMAL':
      default:
        return UrgencyLevel.normal;
    }
  }
}

enum PublisherType { moe, schoolAdmin }

extension PublisherTypeX on PublisherType {
  String toWire() =>
      this == PublisherType.moe ? 'MOE' : 'SCHOOL_ADMIN';

  String label() => this == PublisherType.moe ? 'Ministry' : 'School';

  static PublisherType fromWire(String? s) =>
      s == 'MOE' ? PublisherType.moe : PublisherType.schoolAdmin;
}

class Announcement {
  final int id;
  final int publisherId;
  final PublisherType publisherType;
  final int? schoolId;
  final String title;
  final String content;
  final AnnouncementCategory category;
  final UrgencyLevel urgencyLevel;
  final DateTime datePosted;

  const Announcement({
    required this.id,
    required this.publisherId,
    required this.publisherType,
    required this.schoolId,
    required this.title,
    required this.content,
    required this.category,
    required this.urgencyLevel,
    required this.datePosted,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
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
    return Announcement(
      id: parseInt(json['id']),
      publisherId: parseInt(json['publisherId']),
      publisherType:
          PublisherTypeX.fromWire(json['publisherType'] as String?),
      schoolId: parseIntOrNull(json['schoolId']),
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      category: AnnouncementCategoryX.fromWire(json['category'] as String?),
      urgencyLevel:
          UrgencyLevelX.fromWire(json['urgencyLevel'] as String?),
      datePosted: parseDate(json['datePosted'] ?? json['createdAt']),
    );
  }
}

class AnnouncementInput {
  final String title;
  final String content;
  final AnnouncementCategory category;
  final UrgencyLevel urgencyLevel;
  final int? schoolId;

  const AnnouncementInput({
    required this.title,
    required this.content,
    required this.category,
    required this.urgencyLevel,
    required this.schoolId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'category': category.toWire(),
        'urgencyLevel': urgencyLevel.toWire(),
        if (schoolId != null) 'schoolId': schoolId,
      };
}
