class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: _parseRole(map['role']),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
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
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
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
