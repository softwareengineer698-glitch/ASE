/// Models for delivery confirmation system with photo uploads and signatures
/// Handles delivery verification, documentation, and confirmation workflow

class DeliveryConfirmation {
  final String id;
  final String donationId;
  final String donorId;
  final String ngoId;
  final String donorName;
  final String ngoName;
  final DateTime deliveryDate;
  final DeliveryStatus status;
  final List<DeliveryPhoto> photos;
  final DeliverySignature? donorSignature;
  final DeliverySignature? ngoSignature;
  final String? notes;
  final double quantityDelivered;
  final String foodCategory;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? rejectionReason;

  const DeliveryConfirmation({
    required this.id,
    required this.donationId,
    required this.donorId,
    required this.ngoId,
    required this.donorName,
    required this.ngoName,
    required this.deliveryDate,
    required this.status,
    required this.photos,
    this.donorSignature,
    this.ngoSignature,
    this.notes,
    required this.quantityDelivered,
    required this.foodCategory,
    required this.createdAt,
    this.confirmedAt,
    this.rejectionReason,
  });

  factory DeliveryConfirmation.fromMap(Map<String, dynamic> map) {
    return DeliveryConfirmation(
      id: map['id'] ?? '',
      donationId: map['donationId'] ?? '',
      donorId: map['donorId'] ?? '',
      ngoId: map['ngoId'] ?? '',
      donorName: map['donorName'] ?? '',
      ngoName: map['ngoName'] ?? '',
      deliveryDate: DateTime.parse(map['deliveryDate'] ?? DateTime.now().toIso8601String()),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      photos: (map['photos'] as List<dynamic>? ?? [])
          .map((photo) => DeliveryPhoto.fromMap(photo))
          .toList(),
      donorSignature: map['donorSignature'] != null 
          ? DeliverySignature.fromMap(map['donorSignature'])
          : null,
      ngoSignature: map['ngoSignature'] != null 
          ? DeliverySignature.fromMap(map['ngoSignature'])
          : null,
      notes: map['notes'],
      quantityDelivered: (map['quantityDelivered'] ?? 0).toDouble(),
      foodCategory: map['foodCategory'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      confirmedAt: map['confirmedAt'] != null 
          ? DateTime.parse(map['confirmedAt'])
          : null,
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donationId': donationId,
      'donorId': donorId,
      'ngoId': ngoId,
      'donorName': donorName,
      'ngoName': ngoName,
      'deliveryDate': deliveryDate.toIso8601String(),
      'status': status.name,
      'photos': photos.map((photo) => photo.toMap()).toList(),
      'donorSignature': donorSignature?.toMap(),
      'ngoSignature': ngoSignature?.toMap(),
      'notes': notes,
      'quantityDelivered': quantityDelivered,
      'foodCategory': foodCategory,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  DeliveryConfirmation copyWith({
    String? id,
    String? donationId,
    String? donorId,
    String? ngoId,
    String? donorName,
    String? ngoName,
    DateTime? deliveryDate,
    DeliveryStatus? status,
    List<DeliveryPhoto>? photos,
    DeliverySignature? donorSignature,
    DeliverySignature? ngoSignature,
    String? notes,
    double? quantityDelivered,
    String? foodCategory,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? rejectionReason,
  }) {
    return DeliveryConfirmation(
      id: id ?? this.id,
      donationId: donationId ?? this.donationId,
      donorId: donorId ?? this.donorId,
      ngoId: ngoId ?? this.ngoId,
      donorName: donorName ?? this.donorName,
      ngoName: ngoName ?? this.ngoName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      donorSignature: donorSignature ?? this.donorSignature,
      ngoSignature: ngoSignature ?? this.ngoSignature,
      notes: notes ?? this.notes,
      quantityDelivered: quantityDelivered ?? this.quantityDelivered,
      foodCategory: foodCategory ?? this.foodCategory,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isComplete => 
      photos.isNotEmpty && 
      donorSignature != null && 
      ngoSignature != null;

  bool get requiresAction => 
      status == DeliveryStatus.pending || 
      status == DeliveryStatus.inProgress;

  String get statusDisplayName => status.displayName;
  String get formattedDeliveryDate => 
      '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}';
}

/// Delivery status enumeration
enum DeliveryStatus {
  pending,
  inProgress,
  completed,
  confirmed,
  rejected;

  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.inProgress:
        return 'In Progress';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.confirmed:
        return 'Confirmed';
      case DeliveryStatus.rejected:
        return 'Rejected';
    }
  }

  int get colorValue {
    switch (this) {
      case DeliveryStatus.pending:
        return 0xFFFF9800; // Orange
      case DeliveryStatus.inProgress:
        return 0xFF2196F3; // Blue
      case DeliveryStatus.completed:
        return 0xFF4CAF50; // Green
      case DeliveryStatus.confirmed:
        return 0xFF8BC34A; // Light Green
      case DeliveryStatus.rejected:
        return 0xFFF44336; // Red
    }
  }
}

/// Photo documentation for delivery
class DeliveryPhoto {
  final String id;
  final String filePath;
  final String? firebaseUrl;
  final PhotoType type;
  final DateTime capturedAt;
  final String? caption;
  final double? latitude;
  final double? longitude;

  const DeliveryPhoto({
    required this.id,
    required this.filePath,
    this.firebaseUrl,
    required this.type,
    required this.capturedAt,
    this.caption,
    this.latitude,
    this.longitude,
  });

  factory DeliveryPhoto.fromMap(Map<String, dynamic> map) {
    return DeliveryPhoto(
      id: map['id'] ?? '',
      filePath: map['filePath'] ?? '',
      firebaseUrl: map['firebaseUrl'],
      type: PhotoType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PhotoType.delivery,
      ),
      capturedAt: DateTime.parse(map['capturedAt'] ?? DateTime.now().toIso8601String()),
      caption: map['caption'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'firebaseUrl': firebaseUrl,
      'type': type.name,
      'capturedAt': capturedAt.toIso8601String(),
      'caption': caption,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get typeDisplayName => type.displayName;
  bool get hasLocation => latitude != null && longitude != null;
}

/// Photo type enumeration
enum PhotoType {
  delivery,
  food,
  recipient,
  location,
  damage;

  String get displayName {
    switch (this) {
      case PhotoType.delivery:
        return 'Delivery Photo';
      case PhotoType.food:
        return 'Food Items';
      case PhotoType.recipient:
        return 'Recipient';
      case PhotoType.location:
        return 'Location';
      case PhotoType.damage:
        return 'Damage Report';
    }
  }
}

/// Digital signature for delivery confirmation
class DeliverySignature {
  final String id;
  final String signatureData; // Base64 encoded signature
  final String signerName;
  final String signerRole; // 'donor' or 'ngo'
  final DateTime signedAt;
  final String? signerEmail;

  const DeliverySignature({
    required this.id,
    required this.signatureData,
    required this.signerName,
    required this.signerRole,
    required this.signedAt,
    this.signerEmail,
  });

  factory DeliverySignature.fromMap(Map<String, dynamic> map) {
    return DeliverySignature(
      id: map['id'] ?? '',
      signatureData: map['signatureData'] ?? '',
      signerName: map['signerName'] ?? '',
      signerRole: map['signerRole'] ?? '',
      signedAt: DateTime.parse(map['signedAt'] ?? DateTime.now().toIso8601String()),
      signerEmail: map['signerEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'signatureData': signatureData,
      'signerName': signerName,
      'signerRole': signerRole,
      'signedAt': signedAt.toIso8601String(),
      'signerEmail': signerEmail,
    };
  }

  String get formattedSignedAt => 
      '${signedAt.day}/${signedAt.month}/${signedAt.year} ${signedAt.hour}:${signedAt.minute.toString().padLeft(2, '0')}';
}

/// Delivery confirmation template for different scenarios
class DeliveryTemplate {
  final String id;
  final String name;
  final String description;
  final List<PhotoType> requiredPhotos;
  final bool requiresDonorSignature;
  final bool requiresNgoSignature;
  final List<String> checklistItems;

  const DeliveryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredPhotos,
    required this.requiresDonorSignature,
    required this.requiresNgoSignature,
    required this.checklistItems,
  });

  static const Map<String, DeliveryTemplate> templates = {
    'standard': DeliveryTemplate(
      id: 'standard',
      name: 'Standard Delivery',
      description: 'Standard food delivery confirmation',
      requiredPhotos: [PhotoType.delivery, PhotoType.food],
      requiresDonorSignature: true,
      requiresNgoSignature: true,
      checklistItems: [
        'Food items delivered in good condition',
        'Quantity matches the donation record',
        'Recipient organization confirmed',
        'Delivery location verified',
      ],
    ),
    'emergency': DeliveryTemplate(
      id: 'emergency',
      name: 'Emergency Delivery',
      description: 'Emergency food delivery confirmation',
      requiredPhotos: [PhotoType.delivery, PhotoType.recipient],
      requiresDonorSignature: false,
      requiresNgoSignature: true,
      checklistItems: [
        'Emergency delivery completed',
        'Recipients identified',
        'Food distributed safely',
      ],
    ),
    'bulk': DeliveryTemplate(
      id: 'bulk',
      name: 'Bulk Delivery',
      description: 'Large quantity delivery confirmation',
      requiredPhotos: [PhotoType.delivery, PhotoType.food, PhotoType.location],
      requiresDonorSignature: true,
      requiresNgoSignature: true,
      checklistItems: [
        'All items delivered and counted',
        'Storage facility confirmed',
        'Quality inspection completed',
        'Distribution plan in place',
      ],
    ),
  };
}
