class Achievement {  
  final int id;  
  final int schoolId;  
  final String? schoolName;
  final String title;  
  final String? description;  
  final String tier;  
  final int score;  
  final int year;  
  final String status;  
  final List<String>? documents;  
  final DateTime submittedAt;  
  final DateTime? reviewedAt;  
  final int? reviewedById;  
  final String? reviewNotes;  
  
  Achievement({  
    required this.id,  
    required this.schoolId,  
    this.schoolName,
    required this.title,  
    this.description,  
    required this.tier,  
    required this.score,  
    required this.year,  
    required this.status,  
    this.documents,  
    required this.submittedAt,  
    this.reviewedAt,  
    this.reviewedById,  
    this.reviewNotes,  
  });  
  
  factory Achievement.fromJson(Map<String, dynamic> json) {  
    return Achievement(  
      id: json['id'] as int,  
      schoolId: json['schoolId'] as int,  
      schoolName: json['school']?['schoolName'] as String?,
      title: json['title'] as String,  
      description: json['description'] as String?,  
      tier: json['tier'] as String,  
      score: json['score'] as int,  
      year: json['year'] as int,  
      status: json['status'] as String,  
      documents: json['documents'] != null   
          ? (json['documents'] as List).map((e) => e as String).toList()  
          : null,  
      submittedAt: DateTime.parse(json['submittedAt'] as String),  
      reviewedAt: json['reviewedAt'] != null   
          ? DateTime.parse(json['reviewedAt'] as String)  
          : null,  
      reviewedById: json['reviewedById'] as int?,  
      reviewNotes: json['reviewNotes'] as String?,  
    );  
  }  
}  
  
class StaffBreakdown {  
  final int id;  
  final int schoolId;  
  final String educationLevel;  
  final int count;  
  final DateTime updatedAt;  
  
  StaffBreakdown({  
    required this.id,  
    required this.schoolId,  
    required this.educationLevel,  
    required this.count,  
    required this.updatedAt,  
  });  
  
  factory StaffBreakdown.fromJson(Map<String, dynamic> json) {  
    return StaffBreakdown(  
      id: json['id'] as int,  
      schoolId: json['schoolId'] as int,  
      educationLevel: json['educationLevel'] as String,  
      count: json['count'] as int,  
      updatedAt: DateTime.parse(json['updatedAt'] as String),  
    );  
  }  
}