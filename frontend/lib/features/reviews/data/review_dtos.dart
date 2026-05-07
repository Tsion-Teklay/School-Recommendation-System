// DTOs for `/api/reviews/*`. Mirrors the Prisma `Review` model.
//
// Backend response shapes:
//   POST /api/reviews/:schoolId  → { message, review }
//   GET  /api/reviews/school/:id → { message, data: [...] }
//   PUT  /api/reviews/:id        → { message, review }
//   DELETE /api/reviews/:id      → { message }

enum ReviewCategoryTag {
  safety,
  teachingQuality,
  facilities,
  affordability,
  other,
}

extension ReviewCategoryTagX on ReviewCategoryTag {
  String toWire() {
    switch (this) {
      case ReviewCategoryTag.safety:
        return 'SAFETY';
      case ReviewCategoryTag.teachingQuality:
        return 'TEACHING_QUALITY';
      case ReviewCategoryTag.facilities:
        return 'FACILITIES';
      case ReviewCategoryTag.affordability:
        return 'AFFORDABILITY';
      case ReviewCategoryTag.other:
        return 'OTHER';
    }
  }

  String label() {
    switch (this) {
      case ReviewCategoryTag.safety:
        return 'Safety';
      case ReviewCategoryTag.teachingQuality:
        return 'Teaching quality';
      case ReviewCategoryTag.facilities:
        return 'Facilities';
      case ReviewCategoryTag.affordability:
        return 'Affordability';
      case ReviewCategoryTag.other:
        return 'Other';
    }
  }

  static ReviewCategoryTag fromWire(String? s) {
    switch (s) {
      case 'SAFETY':
        return ReviewCategoryTag.safety;
      case 'TEACHING_QUALITY':
        return ReviewCategoryTag.teachingQuality;
      case 'FACILITIES':
        return ReviewCategoryTag.facilities;
      case 'AFFORDABILITY':
        return ReviewCategoryTag.affordability;
      case 'OTHER':
      default:
        return ReviewCategoryTag.other;
    }
  }
}

class Review {
  final int id;
  final int parentId;
  final int schoolId;
  final int rating;
  final String? comment;
  final ReviewCategoryTag categoryTag;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optionally hydrated when the backend `include`s `parent.fullName`.
  final String? parentFullName;

  const Review({
    required this.id,
    required this.parentId,
    required this.schoolId,
    required this.rating,
    required this.comment,
    required this.categoryTag,
    required this.createdAt,
    required this.updatedAt,
    required this.parentFullName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    final parent = (json['parent'] as Map?)?.cast<String, dynamic>();
    return Review(
      id: parseInt(json['id']),
      parentId: parseInt(json['parentId']),
      schoolId: parseInt(json['schoolId']),
      rating: parseInt(json['rating']),
      comment: json['comment'] as String?,
      categoryTag:
          ReviewCategoryTagX.fromWire(json['categoryTag'] as String?),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      parentFullName: parent?['fullName'] as String?,
    );
  }
}

class ReviewInput {
  final int rating;
  final String? comment;
  final ReviewCategoryTag categoryTag;
  const ReviewInput({
    required this.rating,
    required this.comment,
    required this.categoryTag,
  });

  Map<String, dynamic> toJson() => {
        'rating': rating,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        'categoryTag': categoryTag.toWire(),
      };
}
