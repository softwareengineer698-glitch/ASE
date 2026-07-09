class SurplusItem {
  final String id;
  final String donorName;
  final String itemName;
  final String category;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final String location;
  final String description;
  final SurplusStatus status;
  final DateTime createdAt;

  SurplusItem({
    required this.id,
    required this.donorName,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory SurplusItem.fromMap(Map<String, dynamic> map) {
    return SurplusItem(
      id: map['id'] ?? '',
      donorName: map['donorName'] ?? '',
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
      expiryDate: DateTime.parse(map['expiryDate'] ?? DateTime.now().toIso8601String()),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      status: SurplusStatus.values.firstWhere(
        (e) => e.toString() == 'SurplusStatus.${map['status']}',
        orElse: () => SurplusStatus.available,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorName': donorName,
      'itemName': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate.toIso8601String(),
      'location': location,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get urgencyLevel {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    if (daysUntilExpiry <= 1) return 'Critical';
    if (daysUntilExpiry <= 3) return 'High';
    if (daysUntilExpiry <= 7) return 'Medium';
    return 'Low';
  }

  bool get isExpiringSoon {
    return expiryDate.difference(DateTime.now()).inDays <= 3;
  }
}

enum SurplusStatus {
  available,
  reserved,
  collected,
  expired,
}

extension SurplusStatusExtension on SurplusStatus {
  String get displayName {
    switch (this) {
      case SurplusStatus.available:
        return 'Available';
      case SurplusStatus.reserved:
        return 'Reserved';
      case SurplusStatus.collected:
        return 'Collected';
      case SurplusStatus.expired:
        return 'Expired';
    }
  }
}
