import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String category;
  final double quantity;
  final String unit;
  final String location;
  final List<String> imageUrls;
  final DateTime timestamp;
  final DateTime expiryTime;
  final DonationStatus status;
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
    this.status = DonationStatus.available,
    this.claimedBy,
    this.claimedAt,
    this.completedAt,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'title': title,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'imageUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
      'expiryTime': expiryTime.toIso8601String(),
      'status': status.name,
      'claimedBy': claimedBy,
      'claimedAt': claimedAt != null ? FieldValue.serverTimestamp() : null,
      'completedAt': completedAt != null ? FieldValue.serverTimestamp() : null,
    };
  }

  // Create from map for Firestore
  factory DonationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DonationModel(
      id: documentId,
      donorId: map['donorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      location: map['location'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      expiryTime: DateTime.parse(map['expiryTime'] as String),
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

  static DonationStatus _parseStatus(dynamic statusValue) {
    if (statusValue == null) return DonationStatus.available;

    final statusString = statusValue.toString();

    // Handle both enum string format and name format
    for (final status in DonationStatus.values) {
      if (status.toString() == statusString || status.name == statusString) {
        return status;
      }
    }

    return DonationStatus.available; // Default fallback
  }

  // Copy with method for updates
  DonationModel copyWith({
    String? id,
    String? donorId,
    String? title,
    String? description,
    String? category,
    double? quantity,
    String? unit,
    String? location,
    List<String>? imageUrls,
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
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      timestamp: timestamp ?? this.timestamp,
      expiryTime: expiryTime ?? this.expiryTime,
      status: status ?? this.status,
      claimedBy: claimedBy ?? this.claimedBy,
      claimedAt: claimedAt ?? this.claimedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiryTime);
  bool get isExpiringSoon =>
      expiryTime.difference(DateTime.now()).inHours <= 24;
  bool get isAvailable => status == DonationStatus.available && !isExpired;
  bool get isClaimed => status == DonationStatus.claimed;
  bool get isCompleted => status == DonationStatus.completed;
  bool get isExpiredStatus => status == DonationStatus.expired;

  String get formattedExpiryDate {
    final now = DateTime.now();
    final difference = expiryTime.difference(now).inDays;

    if (difference < 0) {
      return 'Expired ${(-difference)} days ago';
    } else if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else if (difference <= 7) {
      return 'Expires in $difference days';
    } else {
      return 'Expires on ${expiryTime.day}/${expiryTime.month}/${expiryTime.year}';
    }
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get statusDisplayName {
    switch (status) {
      case DonationStatus.available:
        return isExpired ? 'Expired' : 'Available';
      case DonationStatus.claimed:
        return 'Claimed';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.expired:
        return 'Expired';
    }
  }

  String get statusDescription {
    switch (status) {
      case DonationStatus.available:
        return isExpired ? 'Past expiry date' : 'Ready for pickup';
      case DonationStatus.claimed:
        return 'Claimed by NGO';
      case DonationStatus.completed:
        return 'Successfully donated';
      case DonationStatus.expired:
        return 'Expired and removed';
    }
  }
}

enum DonationStatus {
  available,
  claimed,
  completed,
  expired,
}

extension DonationStatusExtension on DonationStatus {
  String get displayName {
    switch (this) {
      case DonationStatus.available:
        return 'Available';
      case DonationStatus.claimed:
        return 'Claimed';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.expired:
        return 'Expired';
    }
  }

  String get description {
    switch (this) {
      case DonationStatus.available:
        return 'Ready for pickup';
      case DonationStatus.claimed:
        return 'Claimed by NGO';
      case DonationStatus.completed:
        return 'Successfully donated';
      case DonationStatus.expired:
        return 'Expired and removed';
    }
  }
}
