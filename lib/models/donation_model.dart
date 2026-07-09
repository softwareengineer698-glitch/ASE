import 'package:cloud_firestore/cloud_firestore.dart';

/// Broad top-level category (food vs. non-food items)
enum DonationItemType { food, clothes, books, medicines, household, other }

extension DonationItemTypeExt on DonationItemType {
  String get displayName {
    switch (this) {
      case DonationItemType.food:
        return 'Food';
      case DonationItemType.clothes:
        return 'Clothes';
      case DonationItemType.books:
        return 'Books';
      case DonationItemType.medicines:
        return 'Medicines';
      case DonationItemType.household:
        return 'Household Items';
      case DonationItemType.other:
        return 'Other';
    }
  }
}

class DonationModel {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String category;
  final DonationItemType itemType;
  final double quantity;
  // Remaining quantity after partial claims
  final double remainingQuantity;
  final String unit;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final List<String> imagePublicIds;
  final DateTime timestamp;
  final DateTime expiryTime;
  final DonationStatus status;
  // For backwards-compat single-claim; partial claims stored in sub-collection
  final String? claimedBy;
  final DateTime? claimedAt;
  final DateTime? completedAt;

  DonationModel({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.imageUrls,
    required this.timestamp,
    required this.expiryTime,
    this.imagePublicIds = const [],
    this.itemType = DonationItemType.food,
    double? remainingQuantity,
    this.latitude,
    this.longitude,
    this.status = DonationStatus.available,
    this.claimedBy,
    this.claimedAt,
    this.completedAt,
  }) : remainingQuantity = remainingQuantity ?? quantity;

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'title': title,
      'description': description,
      'category': category,
      'itemType': itemType.name,
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'unit': unit,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'imagePublicIds': imagePublicIds,
      'timestamp': FieldValue.serverTimestamp(),
      'expiryTime': expiryTime.toIso8601String(),
      'status': status.name,
      'claimedBy': claimedBy,
      'claimedAt': claimedAt != null ? FieldValue.serverTimestamp() : null,
      'completedAt': completedAt != null ? FieldValue.serverTimestamp() : null,
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map, String documentId) {
    final qty = (map['quantity'] as num?)?.toDouble() ?? 0.0;
    return DonationModel(
      id: documentId,
      donorId: map['donorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      itemType: _parseItemType(map['itemType']),
      quantity: qty,
      remainingQuantity: (map['remainingQuantity'] as num?)?.toDouble() ?? qty,
      unit: map['unit'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      imagePublicIds: List<String>.from(map['imagePublicIds'] ?? []),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      expiryTime: DateTime.parse(
          (map['expiryTime'] as String?) ?? DateTime.now().toIso8601String()),
      status: _parseStatus(map['status']),
      claimedBy: map['claimedBy'],
      claimedAt: map['claimedAt'] != null
          ? (map['claimedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  static DonationItemType _parseItemType(dynamic v) {
    if (v == null) return DonationItemType.food;
    for (final t in DonationItemType.values) {
      if (t.name == v.toString()) return t;
    }
    return DonationItemType.food;
  }

  static DonationStatus _parseStatus(dynamic statusValue) {
    if (statusValue == null) return DonationStatus.available;
    final s = statusValue.toString();
    for (final status in DonationStatus.values) {
      if (status.toString() == s || status.name == s) return status;
    }
    return DonationStatus.available;
  }

  DonationModel copyWith({
    String? id,
    String? donorId,
    String? title,
    String? description,
    String? category,
    DonationItemType? itemType,
    double? quantity,
    double? remainingQuantity,
    String? unit,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    List<String>? imagePublicIds,
    DateTime? timestamp,
    DateTime? expiryTime,
    DonationStatus? status,
    String? claimedBy,
    DateTime? claimedAt,
    DateTime? completedAt,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      imagePublicIds: imagePublicIds ?? this.imagePublicIds,
      timestamp: timestamp ?? this.timestamp,
      expiryTime: expiryTime ?? this.expiryTime,
      status: status ?? this.status,
      claimedBy: claimedBy ?? this.claimedBy,
      claimedAt: claimedAt ?? this.claimedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool get isExpired => DateTime.now().isAfter(expiryTime);
  bool get isExpiringSoon =>
      expiryTime.difference(DateTime.now()).inHours <= 24;
  bool get isAvailable =>
      status == DonationStatus.available && !isExpired && remainingQuantity > 0;
  bool get isClaimed => status == DonationStatus.claimed;
  bool get isCompleted => status == DonationStatus.completed;
  bool get isExpiredStatus => status == DonationStatus.expired;
  bool get hasRemainingQuantity => remainingQuantity > 0;

  String get formattedExpiryDate {
    final now = DateTime.now();
    final difference = expiryTime.difference(now).inDays;
    if (difference < 0) return 'Expired ${(-difference)} days ago';
    if (difference == 0) return 'Expires today';
    if (difference == 1) return 'Expires tomorrow';
    if (difference <= 7) return 'Expires in $difference days';
    return 'Expires on ${expiryTime.day}/${expiryTime.month}/${expiryTime.year}';
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
        'at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get statusDisplayName {
    switch (status) {
      case DonationStatus.available:
        return isExpired ? 'Expired' : 'Available';
      case DonationStatus.partiallyClaimed:
        return 'Partially Claimed';
      case DonationStatus.claimed:
        return 'Claimed';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.expired:
        return 'Expired';
    }
  }
}

// ── Tracking status ──────────────────────────────────────────────────────────
enum DonationStatus {
  available,
  partiallyClaimed, // some quantity claimed, rest still available
  claimed, // fully claimed
  completed, // pickup done
  expired,
}

extension DonationStatusExtension on DonationStatus {
  String get displayName {
    switch (this) {
      case DonationStatus.available:
        return 'Available';
      case DonationStatus.partiallyClaimed:
        return 'Partially Claimed';
      case DonationStatus.claimed:
        return 'Fully Claimed';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.expired:
        return 'Expired';
    }
  }
}
