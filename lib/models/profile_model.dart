class ProfileModel {
  final String userId;
  final String? name;
  final String? phone;
  final String? address;
  final String? organization; // For NGOs
  final String? description;
  final DateTime? updatedAt;

  ProfileModel({
    required this.userId,
    this.name,
    this.phone,
    this.address,
    this.organization,
    this.description,
    this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      userId: map['userId'] ?? '',
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      organization: map['organization'],
      description: map['description'],
      updatedAt: map['updatedAt'] != null 
        ? DateTime.parse(map['updatedAt']) 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'organization': organization,
      'description': description,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? userId,
    String? name,
    String? phone,
    String? address,
    String? organization,
    String? description,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      organization: organization ?? this.organization,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
