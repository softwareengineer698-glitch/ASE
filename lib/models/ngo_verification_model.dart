/// Models for NGO verification and admin panel system
/// Handles document verification, admin workflows, and NGO management
library;

class NGOVerification {
  final String id;
  final String ngoId;
  final String ngoName;
  final String contactEmail;
  final String contactPhone;
  final String registrationNumber;
  final String address;
  final VerificationStatus status;
  final List<VerificationDocument> documents;
  final List<VerificationStep> steps;
  final String? adminId;
  final String? adminNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const NGOVerification({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.contactEmail,
    required this.contactPhone,
    required this.registrationNumber,
    required this.address,
    required this.status,
    required this.documents,
    required this.steps,
    required this.submittedAt, this.adminId,
    this.adminNotes,
    this.reviewedAt,
    this.approvedAt,
    this.rejectionReason,
  });

  factory NGOVerification.fromMap(Map<String, dynamic> map) {
    return NGOVerification(
      id: map['id'] ?? '',
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      address: map['address'] ?? '',
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      documents: (map['documents'] as List<dynamic>? ?? [])
          .map((doc) => VerificationDocument.fromMap(doc))
          .toList(),
      steps: (map['steps'] as List<dynamic>? ?? [])
          .map((step) => VerificationStep.fromMap(step))
          .toList(),
      adminId: map['adminId'],
      adminNotes: map['adminNotes'],
      submittedAt: DateTime.parse(map['submittedAt'] ?? DateTime.now().toIso8601String()),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'registrationNumber': registrationNumber,
      'address': address,
      'status': status.name,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'steps': steps.map((step) => step.toMap()).toList(),
      'adminId': adminId,
      'adminNotes': adminNotes,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  NGOVerification copyWith({
    String? id,
    String? ngoId,
    String? ngoName,
    String? contactEmail,
    String? contactPhone,
    String? registrationNumber,
    String? address,
    VerificationStatus? status,
    List<VerificationDocument>? documents,
    List<VerificationStep>? steps,
    String? adminId,
    String? adminNotes,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return NGOVerification(
      id: id ?? this.id,
      ngoId: ngoId ?? this.ngoId,
      ngoName: ngoName ?? this.ngoName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      address: address ?? this.address,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      steps: steps ?? this.steps,
      adminId: adminId ?? this.adminId,
      adminNotes: adminNotes ?? this.adminNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isComplete => documents.every((doc) => doc.status == DocumentStatus.approved);
  bool get requiresAction => status == VerificationStatus.pending || status == VerificationStatus.underReview;
  String get statusDisplayName => status.displayName;
  double get completionPercentage {
    if (steps.isEmpty) return 0.0;
    final completedSteps = steps.where((step) => step.isCompleted).length;
    return completedSteps / steps.length;
  }
}

/// NGO verification status enumeration
enum VerificationStatus {
  pending,
  underReview,
  approved,
  rejected,
  suspended;

  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.underReview:
        return 'Under Review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.suspended:
        return 'Suspended';
    }
  }

  int get colorValue {
    switch (this) {
      case VerificationStatus.pending:
        return 0xFFFF9800; // Orange
      case VerificationStatus.underReview:
        return 0xFF2196F3; // Blue
      case VerificationStatus.approved:
        return 0xFF4CAF50; // Green
      case VerificationStatus.rejected:
        return 0xFFF44336; // Red
      case VerificationStatus.suspended:
        return 0xFF9C27B0; // Purple
    }
  }
}

/// Verification document model
class VerificationDocument {
  final String id;
  final DocumentType type;
  final String fileName;
  final String filePath;
  final String? firebaseUrl;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final String? reviewNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const VerificationDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.filePath,
    required this.status, required this.uploadedAt, this.firebaseUrl,
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory VerificationDocument.fromMap(Map<String, dynamic> map) {
    return VerificationDocument(
      id: map['id'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.registration,
      ),
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      firebaseUrl: map['firebaseUrl'],
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DocumentStatus.pending,
      ),
      uploadedAt: DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
      reviewNotes: map['reviewNotes'],
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'fileName': fileName,
      'filePath': filePath,
      'firebaseUrl': firebaseUrl,
      'status': status.name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'reviewNotes': reviewNotes,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  String get typeDisplayName => type.displayName;
  String get statusDisplayName => status.displayName;
}

/// Document type enumeration
enum DocumentType {
  registration,
  taxExemption,
  bankStatement,
  auditReport,
  boardResolution,
  projectProposal,
  impactReport;

  String get displayName {
    switch (this) {
      case DocumentType.registration:
        return 'Registration Certificate';
      case DocumentType.taxExemption:
        return 'Tax Exemption Certificate';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.auditReport:
        return 'Audit Report';
      case DocumentType.boardResolution:
        return 'Board Resolution';
      case DocumentType.projectProposal:
        return 'Project Proposal';
      case DocumentType.impactReport:
        return 'Impact Report';
    }
  }

  bool get isRequired {
    switch (this) {
      case DocumentType.registration:
      case DocumentType.taxExemption:
      case DocumentType.bankStatement:
        return true;
      default:
        return false;
    }
  }
}

/// Document status enumeration
enum DocumentStatus {
  pending,
  approved,
  rejected,
  expired;

  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending Review';
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }
}

/// Verification step model
class VerificationStep {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool isRequired;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;

  const VerificationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.isRequired,
    required this.isCompleted,
    this.completedAt,
    this.completedBy,
    this.notes,
  });

  factory VerificationStep.fromMap(Map<String, dynamic> map) {
    return VerificationStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      isRequired: map['isRequired'] ?? true,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      completedBy: map['completedBy'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'isRequired': isRequired,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'notes': notes,
    };
  }

  VerificationStep copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    bool? isRequired,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
  }) {
    return VerificationStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
    );
  }
}

/// Admin user model
class AdminUser {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final List<String> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: AdminRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => AdminRole.reviewer,
      ),
      permissions: List<String>.from(map['permissions'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  String get roleDisplayName => role.displayName;
  bool hasPermission(String permission) => permissions.contains(permission);
}

/// Admin role enumeration
enum AdminRole {
  superAdmin,
  admin,
  reviewer,
  moderator;

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.reviewer:
        return 'Reviewer';
      case AdminRole.moderator:
        return 'Moderator';
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case AdminRole.superAdmin:
        return ['all'];
      case AdminRole.admin:
        return ['approve_ngo', 'reject_ngo', 'manage_users', 'view_reports'];
      case AdminRole.reviewer:
        return ['review_documents', 'view_applications'];
      case AdminRole.moderator:
        return ['moderate_content', 'view_reports'];
    }
  }
}
