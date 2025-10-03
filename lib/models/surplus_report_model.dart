import 'package:cloud_firestore/cloud_firestore.dart';

class SurplusReportModel {
  final String id;
  final String donorId;
  final String foodType;
  final int quantity;
  final DateTime expiry;
  final DateTime timestamp;
  final String? description;
  final String status; // 'available', 'requested', 'completed'

  SurplusReportModel({
    required this.id,
    required this.donorId,
    required this.foodType,
    required this.quantity,
    required this.expiry,
    required this.timestamp,
    this.description,
    this.status = 'available',
  });

  factory SurplusReportModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SurplusReportModel(
      id: documentId,
      donorId: map['donorId'] ?? '',
      foodType: map['foodType'] ?? '',
      quantity: map['quantity'] ?? 0,
      expiry: (map['expiry'] as Timestamp).toDate(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      description: map['description'],
      status: map['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'foodType': foodType,
      'quantity': quantity,
      'expiry': Timestamp.fromDate(expiry),
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'status': status,
    };
  }

  SurplusReportModel copyWith({
    String? id,
    String? donorId,
    String? foodType,
    int? quantity,
    DateTime? expiry,
    DateTime? timestamp,
    String? description,
    String? status,
  }) {
    return SurplusReportModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      foodType: foodType ?? this.foodType,
      quantity: quantity ?? this.quantity,
      expiry: expiry ?? this.expiry,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}
