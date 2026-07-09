import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus {
  open,
  investigating,
  resolved,
  dismissed,
}

enum ComplaintType {
  donor,
  ngo,
  volunteer,
  system,
  appIssue,
}

class ComplaintModel {
  final String id;
  final String reporterId;
  final String? targetId;
  final ComplaintType type;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? adminId;

  ComplaintModel({
    required this.id,
    required this.reporterId,
    required this.type, required this.subject, required this.description, required this.createdAt, this.targetId,
    this.status = ComplaintStatus.open,
    this.resolvedAt,
    this.resolution,
    this.adminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'type': type.name,
      'subject': subject,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolution': resolution,
      'adminId': adminId,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ComplaintModel(
      id: documentId,
      reporterId: map['reporterId'] ?? '',
      targetId: map['targetId'],
      type: ComplaintType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ComplaintType.system,
      ),
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ComplaintStatus.open,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      resolution: map['resolution'],
      adminId: map['adminId'],
    );
  }
}
