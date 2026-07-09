import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RequestStatus {
  pending,      // Waiting for fulfillment
  fulfilled,    // Donors provided the food
  expired,      // Deadline passed without fulfillment
  cancelled,    // User cancelled request
}

class FoodRequest {
  final String id;
  final String userId;
  final String userName;
  final String organizationName;
  final String foodType;
  final String description;
  final int quantity;
  final String unit;
  final DateTime neededBy;
  final RequestStatus status;
  final DateTime createdAt;
  final String? fulfilledByDonorId;
  final String? fulfilledByDonorName;
  final DateTime? fulfilledAt;
  final String? imageUrl;
  final String? location;
  final bool isUrgent;

  FoodRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.organizationName,
    required this.foodType,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.neededBy,
    required this.status,
    required this.createdAt,
    this.fulfilledByDonorId,
    this.fulfilledByDonorName,
    this.fulfilledAt,
    this.imageUrl,
    this.location,
    this.isUrgent = false,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'organizationName': organizationName,
      'foodType': foodType,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'neededBy': neededBy.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'fulfilledByDonorId': fulfilledByDonorId,
      'fulfilledByDonorName': fulfilledByDonorName,
      'fulfilledAt': fulfilledAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'location': location,
      'isUrgent': isUrgent,
    };
  }

  // Create from Firestore document
  factory FoodRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodRequest(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      organizationName: data['organizationName'] ?? '',
      foodType: data['foodType'] ?? '',
      description: data['description'] ?? '',
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? 'units',
      neededBy: DateTime.tryParse(data['neededBy'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.tryParse(data['createdAt'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      fulfilledByDonorId: data['fulfilledByDonorId'],
      fulfilledByDonorName: data['fulfilledByDonorName'],
      fulfilledAt: data['fulfilledAt'] != null 
          ? DateTime.tryParse(data['fulfilledAt']) 
          : null,
      imageUrl: data['imageUrl'],
      location: data['location'],
      isUrgent: data['isUrgent'] ?? false,
    );
  }

  // Create from map
  factory FoodRequest.fromMap(Map<String, dynamic> map) {
    return FoodRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      organizationName: map['organizationName'] ?? '',
      foodType: map['foodType'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? 'units',
      neededBy: DateTime.tryParse(map['neededBy'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      fulfilledByDonorId: map['fulfilledByDonorId'],
      fulfilledByDonorName: map['fulfilledByDonorName'],
      fulfilledAt: map['fulfilledAt'] != null 
          ? DateTime.tryParse(map['fulfilledAt']) 
          : null,
      imageUrl: map['imageUrl'],
      location: map['location'],
      isUrgent: map['isUrgent'] ?? false,
    );
  }

  // Copy with method
  FoodRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? organizationName,
    String? foodType,
    String? description,
    int? quantity,
    String? unit,
    DateTime? neededBy,
    RequestStatus? status,
    DateTime? createdAt,
    String? fulfilledByDonorId,
    String? fulfilledByDonorName,
    DateTime? fulfilledAt,
    String? imageUrl,
    String? location,
    bool? isUrgent,
  }) {
    return FoodRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      organizationName: organizationName ?? this.organizationName,
      foodType: foodType ?? this.foodType,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      neededBy: neededBy ?? this.neededBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fulfilledByDonorId: fulfilledByDonorId ?? this.fulfilledByDonorId,
      fulfilledByDonorName: fulfilledByDonorName ?? this.fulfilledByDonorName,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  // Helper properties
  bool get isExpired => status == RequestStatus.expired || neededBy.isBefore(DateTime.now());
  bool get isActive => status == RequestStatus.pending && !isExpired;
  int get hoursRemaining => neededBy.difference(DateTime.now()).inHours;
  
  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return hoursRemaining < 0 ? 'Expired' : 'Active';
      case RequestStatus.fulfilled:
        return 'Fulfilled';
      case RequestStatus.expired:
        return 'Expired';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get urgencyLabel {
    if (hoursRemaining < 12) return 'Urgent';
    if (hoursRemaining < 24) return 'Soon';
    return 'Normal';
  }

  Color get urgencyColor {
    if (hoursRemaining < 12) return Colors.red;
    if (hoursRemaining < 24) return Colors.orange;
    return Colors.green;
  }
}

// Common units for food requests
class RequestUnit {
  static const String kg = 'kg';
  static const String grams = 'g';
  static const String pieces = 'pieces';
  static const String boxes = 'boxes';
  static const String liters = 'liters';
  static const String packs = 'packs';
  
  static List<String> get values => [kg, grams, pieces, boxes, liters, packs];
}

// Common food types for quick selection
class FoodType {
  static const String freshVegetables = 'Fresh Vegetables';
  static const String freshFruits = 'Fresh Fruits';
  static const String grains = 'Grains/Rice';
  static const String bread = 'Bread';
  static const String dairy = 'Dairy Products';
  static const String meat = 'Meat';
  static const String cannedFood = 'Canned Food';
  static const String cookedFood = 'Cooked Food';
  static const String snacks = 'Snacks';
  static const String beverages = 'Beverages';
  static const String frozenFood = 'Frozen Food';
  static const String other = 'Other';
  
  static List<String> get values => [
    freshVegetables, freshFruits, grains, bread, dairy, meat, 
    cannedFood, cookedFood, snacks, beverages, frozenFood, other
  ];
}