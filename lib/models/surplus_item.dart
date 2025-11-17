class SurplusItem {
  final String id;
  final String foodType;
  final int quantity;
  final DateTime expiryDate;
  final DateTime reportedDate;
  final String donorName;
  SurplusStatus status;

  SurplusItem({
    required this.id,
    required this.foodType,
    required this.quantity,
    required this.expiryDate,
    required this.reportedDate,
    required this.donorName,
    this.status = SurplusStatus.available,
  });

  // Convert to map for future database integration
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodType': foodType,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'reportedDate': reportedDate.toIso8601String(),
      'donorName': donorName,
      'status': status.name,
    };
  }

  // Create from map for future database integration
  factory SurplusItem.fromMap(Map<String, dynamic> map) {
    return SurplusItem(
      id: map['id'],
      foodType: map['foodType'],
      quantity: map['quantity'],
      expiryDate: DateTime.parse(map['expiryDate']),
      reportedDate: DateTime.parse(map['reportedDate']),
      donorName: map['donorName'],
      status: _parseStatus(map['status']),
    );
  }

  static SurplusStatus _parseStatus(dynamic statusValue) {
    if (statusValue == null) return SurplusStatus.available;

    final statusString = statusValue.toString();

    // Handle both enum string format and name format
    for (final status in SurplusStatus.values) {
      if (status.toString() == statusString || status.name == statusString) {
        return status;
      }
    }

    return SurplusStatus.available; // Default fallback
  }

  // Copy with method for updates
  SurplusItem copyWith({
    String? id,
    String? foodType,
    int? quantity,
    DateTime? expiryDate,
    DateTime? reportedDate,
    String? donorName,
    SurplusStatus? status,
  }) {
    return SurplusItem(
      id: id ?? this.id,
      foodType: foodType ?? this.foodType,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      reportedDate: reportedDate ?? this.reportedDate,
      donorName: donorName ?? this.donorName,
      status: status ?? this.status,
    );
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isExpiringSoon => expiryDate.difference(DateTime.now()).inDays <= 2;

  String get formattedExpiryDate {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (difference < 0) {
      return 'Expired ${(-difference)} days ago';
    } else if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $difference days';
    }
  }
}

enum SurplusStatus {
  available,
  accepted,
  collected,
  expired,
}

extension SurplusStatusExtension on SurplusStatus {
  String get displayName {
    switch (this) {
      case SurplusStatus.available:
        return 'Available';
      case SurplusStatus.accepted:
        return 'Accepted';
      case SurplusStatus.collected:
        return 'Collected';
      case SurplusStatus.expired:
        return 'Expired';
    }
  }

  String get description {
    switch (this) {
      case SurplusStatus.available:
        return 'Ready for pickup';
      case SurplusStatus.accepted:
        return 'Accepted by NGO';
      case SurplusStatus.collected:
        return 'Successfully collected';
      case SurplusStatus.expired:
        return 'Past expiry date';
    }
  }
}
