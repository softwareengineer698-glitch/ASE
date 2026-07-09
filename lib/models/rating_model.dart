import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? donationId;
  final String? claimId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.rating, required this.createdAt, this.donationId,
    this.claimId,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'donationId': donationId,
      'claimId': claimId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RatingModel(
      id: documentId,
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      donationId: map['donationId'],
      claimId: map['claimId'],
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
