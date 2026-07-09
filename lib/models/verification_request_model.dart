import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationRequestStatus {
  pending,
  underReview,
  approved,
  rejected,
}

class VerificationRequestModel {
  final String id;
  final String userId;
  final String role; // 'ngo' or 'volunteer'
  final VerificationRequestStatus status;
  final Map<String, String> documents; // documentType -> url
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? adminId;
  final String? adminNotes;
  final String? rejectionReason;

  VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.documents, required this.submittedAt, this.status = VerificationRequestStatus.pending,
    this.reviewedAt,
    this.adminId,
    this.adminNotes,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'status': status.name,
      'documents': documents,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'adminId': adminId,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
    };
  }

  factory VerificationRequestModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return VerificationRequestModel(
      id: documentId,
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
      status: VerificationRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VerificationRequestStatus.pending,
      ),
      documents: Map<String, String>.from(map['documents'] ?? {}),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      adminId: map['adminId'],
      adminNotes: map['adminNotes'],
      rejectionReason: map['rejectionReason'],
    );
  }
}
