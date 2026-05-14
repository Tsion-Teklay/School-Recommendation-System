class Comment {  
  final int id;  
  final String content;  
  final DateTime timestamp;  
  final String authorName;  
  final List<Comment> replies;  
  Comment({  
    required this.id,  
    required this.content,  
    required this.timestamp,  
    required this.authorName,  
    this.replies = const [],  
  });  
  
  factory Comment.fromJson(Map<String, dynamic> json) => Comment(  
    id: json['id'],  
    content: json['content'],  
    timestamp: DateTime.parse(json['timestamp']),  
    authorName: json['author']['fullName'],  
    replies: (json['replies'] as List?)  
        ?.map((r) => Comment.fromJson(r))  
        .toList() ?? [],  
  );  
}