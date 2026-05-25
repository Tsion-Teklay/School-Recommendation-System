class SchoolDemographics {  
  final int id;  
  final int schoolId;  
  final int academicYear;  
  final int totalStudents;  
  final int girlsCount;  
  final int boysCount;  
  final double passingRate;  
  final double nationalExamScore;  
  final DateTime submittedAt;  
  
  SchoolDemographics({  
    required this.id,  
    required this.schoolId,  
    required this.academicYear,  
    required this.totalStudents,  
    required this.girlsCount,  
    required this.boysCount,  
    required this.passingRate,  
    required this.nationalExamScore,  
    required this.submittedAt,  
  });  
  
  factory SchoolDemographics.fromJson(Map<String, dynamic> json) {
    return SchoolDemographics(
      id: json['id'] as int,
      schoolId: json['schoolId'] as int,
      academicYear: json['academicYear'] as int,
      totalStudents: json['totalStudents'] as int,
      girlsCount: json['girlsCount'] as int,
      boysCount: json['boysCount'] as int,
      // Prisma serialises Decimal columns as Strings when using the MySQL
      // adapter — double.parse handles both String and num safely.
      passingRate: double.parse(json['passingRate'].toString()),
      nationalExamScore: double.parse(json['nationalExamScore'].toString()),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }
}