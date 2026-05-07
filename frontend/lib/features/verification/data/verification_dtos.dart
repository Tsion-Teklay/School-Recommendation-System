// DTOs for `/api/verification-requests` and the school-admin submit route.

enum VerificationRequestStatus { pending, approved, rejected }

extension VerificationRequestStatusX on VerificationRequestStatus {
  String toWire() {
    switch (this) {
      case VerificationRequestStatus.pending:
        return 'PENDING';
      case VerificationRequestStatus.approved:
        return 'APPROVED';
      case VerificationRequestStatus.rejected:
        return 'REJECTED';
    }
  }

  String label() {
    switch (this) {
      case VerificationRequestStatus.pending:
        return 'Pending';
      case VerificationRequestStatus.approved:
        return 'Approved';
      case VerificationRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static VerificationRequestStatus fromWire(String? s) {
    switch (s) {
      case 'APPROVED':
        return VerificationRequestStatus.approved;
      case 'REJECTED':
        return VerificationRequestStatus.rejected;
      case 'PENDING':
      default:
        return VerificationRequestStatus.pending;
    }
  }
}

class VerificationDocument {
  final String url;
  final String? originalName;
  final int? size;
  final String? mimeType;

  const VerificationDocument({
    required this.url,
    required this.originalName,
    required this.size,
    required this.mimeType,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) =>
      VerificationDocument(
        url: (json['url'] ?? '') as String,
        originalName: json['originalName'] as String?,
        size: (json['size'] as num?)?.toInt(),
        mimeType: json['mimeType'] as String?,
      );
}

class VerificationRequest {
  final int id;
  final int schoolId;
  final int submittedById;
  final int? reviewedById;
  final VerificationRequestStatus status;
  final List<VerificationDocument> documents;
  final String? notes;
  final String? reviewNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  /// Optional joined school name (backend may include `school: { schoolName }`).
  final String? schoolName;

  /// Optional joined submitter name.
  final String? submitterName;

  const VerificationRequest({
    required this.id,
    required this.schoolId,
    required this.submittedById,
    required this.reviewedById,
    required this.status,
    required this.documents,
    required this.notes,
    required this.reviewNotes,
    required this.submittedAt,
    required this.reviewedAt,
    required this.schoolName,
    required this.submitterName,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
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
    DateTime? parseDateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }
    final docs = json['documents'];
    final docsList = <VerificationDocument>[];
    if (docs is List) {
      for (final d in docs) {
        if (d is Map) {
          docsList.add(VerificationDocument.fromJson(d.cast<String, dynamic>()));
        } else if (d is String) {
          docsList.add(VerificationDocument(
            url: d,
            originalName: null,
            size: null,
            mimeType: null,
          ));
        }
      }
    }
    final school = (json['school'] as Map?)?.cast<String, dynamic>();
    final submitter = (json['submittedBy'] as Map?)?.cast<String, dynamic>();
    return VerificationRequest(
      id: parseInt(json['id']),
      schoolId: parseInt(json['schoolId']),
      submittedById: parseInt(json['submittedById']),
      reviewedById: parseIntOrNull(json['reviewedById']),
      status: VerificationRequestStatusX.fromWire(json['status'] as String?),
      documents: docsList,
      notes: json['notes'] as String?,
      reviewNotes: json['reviewNotes'] as String?,
      submittedAt: parseDate(json['submittedAt']),
      reviewedAt: parseDateOrNull(json['reviewedAt']),
      schoolName: school?['schoolName'] as String?,
      submitterName: submitter?['fullName'] as String?,
    );
  }
}
