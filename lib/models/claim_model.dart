import 'package:cloud_firestore/cloud_firestore.dart';

/// A single partial or full claim on a donation.
/// Multiple claims can exist per donation (partial claiming support).
class ClaimModel {
  final String id;
  final String donationId;
  final String claimantId;   // uid of person claiming (recipient/NGO)
  final String donorId;
  final double claimedQuantity;
  final String unit;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? chatRoomId;
  final String? notes;

  ClaimModel({
    required this.id,
    required this.donationId,
    required this.claimantId,
    required this.donorId,
    required this.claimedQuantity,
    required this.unit,
    required this.createdAt, this.status = ClaimStatus.pending,
    this.acceptedAt,
    this.pickedUpAt,
    this.completedAt,
    this.cancelledAt,
    this.chatRoomId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'donationId': donationId,
      'claimantId': claimantId,
      'donorId': donorId,
      'claimedQuantity': claimedQuantity,
      'unit': unit,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'chatRoomId': chatRoomId,
      'notes': notes,
    };
  }

  factory ClaimModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? ts(String key) {
      final v = map[key];
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ClaimModel(
      id: documentId,
      donationId: map['donationId'] ?? '',
      claimantId: map['claimantId'] ?? '',
      donorId: map['donorId'] ?? '',
      claimedQuantity: (map['claimedQuantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] ?? '',
      status: ClaimStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ClaimStatus.pending,
      ),
      createdAt: ts('createdAt') ?? DateTime.now(),
      acceptedAt: ts('acceptedAt'),
      pickedUpAt: ts('pickedUpAt'),
      completedAt: ts('completedAt'),
      cancelledAt: ts('cancelledAt'),
      chatRoomId: map['chatRoomId'],
      notes: map['notes'],
    );
  }

  ClaimModel copyWith({
    ClaimStatus? status,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? chatRoomId,
    String? notes,
  }) =>
      ClaimModel(
        id: id,
        donationId: donationId,
        claimantId: claimantId,
        donorId: donorId,
        claimedQuantity: claimedQuantity,
        unit: unit,
        status: status ?? this.status,
        createdAt: createdAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        pickedUpAt: pickedUpAt ?? this.pickedUpAt,
        completedAt: completedAt ?? this.completedAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        chatRoomId: chatRoomId ?? this.chatRoomId,
        notes: notes ?? this.notes,
      );
}

/// Full lifecycle tracking per claim
enum ClaimStatus {
  pending,     // submitted, waiting for donor to accept
  accepted,    // donor accepted — chat enabled
  pickupReady, // donor marked ready for pickup
  pickedUp,    // claimant marked picked up
  completed,   // fully done
  rejected,    // donor rejected
  cancelled,   // auto-cancelled (timeout/expiry)
}

extension ClaimStatusExt on ClaimStatus {
  String get displayName {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.accepted:
        return 'Accepted';
      case ClaimStatus.pickupReady:
        return 'Ready for Pickup';
      case ClaimStatus.pickedUp:
        return 'Picked Up';
      case ClaimStatus.completed:
        return 'Completed';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.cancelled:
        return 'Cancelled';
    }
  }
}
