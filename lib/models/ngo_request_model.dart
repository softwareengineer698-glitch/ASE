import 'package:cloud_firestore/cloud_firestore.dart';

class NGORequestModel {
  final String id;
  final String ngoId;
  final String surplusId;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final DateTime timestamp;
  final String? message;

  NGORequestModel({
    required this.id,
    required this.ngoId,
    required this.surplusId,
    required this.status,
    required this.timestamp,
    this.message,
  });

  factory NGORequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NGORequestModel(
      id: documentId,
      ngoId: map['ngoId'] ?? '',
      surplusId: map['surplusId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ngoId': ngoId,
      'surplusId': surplusId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'message': message,
    };
  }

  NGORequestModel copyWith({
    String? id,
    String? ngoId,
    String? surplusId,
    String? status,
    DateTime? timestamp,
    String? message,
  }) {
    return NGORequestModel(
      id: id ?? this.id,
      ngoId: ngoId ?? this.ngoId,
      surplusId: surplusId ?? this.surplusId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
    );
  }
}
