class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? organizationName;
  final String? userName;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.organizationName,
    this.userName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: _parseRole(map['role']),
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      organizationName: map['organizationName'],
      userName: map['userName'],
    );
  }

  static UserRole _parseRole(dynamic roleValue) {
    if (roleValue == null) return UserRole.donor;

    final roleString = roleValue.toString().toLowerCase();

    // Handle "donor"/"ngo" format from Firestore
    switch (roleString) {
      case 'donor':
        return UserRole.donor;
      case 'ngo':
        return UserRole.ngo;
      default:
        return UserRole.donor; // Default fallback
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.name, // Uses "donor"/"ngo" to match Firestore security rules
      'createdAt': createdAt.toIso8601String(),
      'organizationName': organizationName,
      'userName': userName,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? organizationName,
    String? userName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      organizationName: organizationName ?? this.organizationName,
      userName: userName ?? this.userName,
    );
  }
}

enum UserRole {
  donor,
  ngo,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.donor:
        return 'Donor';
      case UserRole.ngo:
        return 'NGO';
    }
  }
}
