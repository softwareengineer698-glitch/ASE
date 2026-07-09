import 'package:cloud_firestore/cloud_firestore.dart';

enum VolunteerStatus {
  available,
  busy,
  offline,
}

class VolunteerModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final VolunteerStatus status;
  final double latitude;
  final double longitude;
  final int completedDeliveries;
  final double performanceScore;
  final List<String> preferredAreas;
  final bool isVerified;
  final DateTime? lastActive;

  VolunteerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.status = VolunteerStatus.offline,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.completedDeliveries = 0,
    this.performanceScore = 5.0,
    this.preferredAreas = const [],
    this.isVerified = false,
    this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'completedDeliveries': completedDeliveries,
      'performanceScore': performanceScore,
      'preferredAreas': preferredAreas,
      'isVerified': isVerified,
      'lastActive': lastActive != null
          ? Timestamp.fromDate(lastActive!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory VolunteerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VolunteerModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      status: VolunteerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VolunteerStatus.offline,
      ),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      completedDeliveries: map['completedDeliveries'] ?? 0,
      performanceScore: (map['performanceScore'] as num?)?.toDouble() ?? 5.0,
      preferredAreas: List<String>.from(map['preferredAreas'] ?? []),
      isVerified: map['isVerified'] ?? false,
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as Timestamp).toDate()
          : null,
    );
  }

  VolunteerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    VolunteerStatus? status,
    double? latitude,
    double? longitude,
    int? completedDeliveries,
    double? performanceScore,
    List<String>? preferredAreas,
    bool? isVerified,
    DateTime? lastActive,
  }) {
    return VolunteerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      performanceScore: performanceScore ?? this.performanceScore,
      preferredAreas: preferredAreas ?? this.preferredAreas,
      isVerified: isVerified ?? this.isVerified,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
