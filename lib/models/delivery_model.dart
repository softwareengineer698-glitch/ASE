import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStepStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class DeliveryModel {
  final String id;
  final String claimId;
  final String donationId;
  final String volunteerId;
  final String donorId;
  final String ngoId;
  final String status; // 'pending', 'picked_up', 'in_transit', 'delivered'
  final DateTime scheduledAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final double quantityDelivered;
  final String? qrVerificationCode;
  final DateTime? qrScannedAt;
  final List<String> proofPhotos;
  final String? notes;

  DeliveryModel({
    required this.id,
    required this.claimId,
    required this.donationId,
    required this.volunteerId,
    required this.donorId,
    required this.ngoId,
    required this.status,
    required this.scheduledAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.quantityDelivered = 0.0,
    this.qrVerificationCode,
    this.qrScannedAt,
    this.proofPhotos = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'donationId': donationId,
      'volunteerId': volunteerId,
      'donorId': donorId,
      'ngoId': ngoId,
      'status': status,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'quantityDelivered': quantityDelivered,
      'qrVerificationCode': qrVerificationCode,
      'qrScannedAt':
          qrScannedAt != null ? Timestamp.fromDate(qrScannedAt!) : null,
      'proofPhotos': proofPhotos,
      'notes': notes,
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DeliveryModel(
      id: documentId,
      claimId: map['claimId'] ?? '',
      donationId: map['donationId'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      donorId: map['donorId'] ?? '',
      ngoId: map['ngoId'] ?? '',
      status: map['status'] ?? 'pending',
      scheduledAt: (map['scheduledAt'] as Timestamp).toDate(),
      pickedUpAt: map['pickedUpAt'] != null
          ? (map['pickedUpAt'] as Timestamp).toDate()
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      quantityDelivered: (map['quantityDelivered'] as num?)?.toDouble() ?? 0.0,
      qrVerificationCode: map['qrVerificationCode'],
      qrScannedAt: map['qrScannedAt'] != null
          ? (map['qrScannedAt'] as Timestamp).toDate()
          : null,
      proofPhotos: List<String>.from(map['proofPhotos'] ?? []),
      notes: map['notes'],
    );
  }
}
