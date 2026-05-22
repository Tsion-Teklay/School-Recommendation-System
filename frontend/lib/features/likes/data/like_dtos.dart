enum LikeTargetType { announcement, forumPost }

class LikeToggleRequest {
  final LikeTargetType targetType;
  final int targetId;
  LikeToggleRequest({required this.targetType, required this.targetId});

  Map<String, dynamic> toJson() => {
        'targetType': targetType == LikeTargetType.announcement
            ? 'ANNOUNCEMENT'
            : 'FORUM_POST',
        'targetId': targetId,
      };
}

class LikeToggleResponse {
  final bool liked;
  LikeToggleResponse({required this.liked});

  factory LikeToggleResponse.fromJson(Map<String, dynamic> json) =>
      LikeToggleResponse(liked: json['liked']);
}

class LikeCountResponse {
  final int count;
  LikeCountResponse({required this.count});

  factory LikeCountResponse.fromJson(Map<String, dynamic> json) =>
      LikeCountResponse(count: json['count']);
}
