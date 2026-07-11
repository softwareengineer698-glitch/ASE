import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? organizationName;
  final String? userName;
  final bool isVerified;
  // Phone / OTP fields
  final String? phoneNumber;
  final bool phoneVerified;
  final bool emailVerified;
  final bool roleSelected;
  // Donation category (food, non-food)
  final String? preferredCategory;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.organizationName,
    this.userName,
    this.isVerified = false,
    this.phoneNumber,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.roleSelected = false,
    this.preferredCategory,
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
      isVerified: map['isVerified'] ?? false,
      phoneNumber: map['phoneNumber'],
      phoneVerified: map['phoneVerified'] ?? false,
      emailVerified: map['emailVerified'] ?? false,
      roleSelected: map['roleSelected'] ?? false,
      preferredCategory: map['preferredCategory'],
    );
  }

  static UserRole _parseRole(dynamic roleValue) {
    if (roleValue == null) return UserRole.donor;
    final roleString = roleValue.toString().toLowerCase();
    switch (roleString) {
      case 'donor':
        return UserRole.donor;
      case 'ngo':
        return UserRole.ngo;
      case 'volunteer':
        return UserRole.volunteer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.donor;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'organizationName': organizationName,
      'userName': userName,
      'isVerified': isVerified,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'roleSelected': roleSelected,
      'preferredCategory': preferredCategory,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? organizationName,
    String? userName,
    bool? isVerified,
    String? phoneNumber,
    bool? phoneVerified,
    bool? emailVerified,
    bool? roleSelected,
    String? preferredCategory,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      organizationName: organizationName ?? this.organizationName,
      userName: userName ?? this.userName,
      isVerified: isVerified ?? this.isVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      roleSelected: roleSelected ?? this.roleSelected,
      preferredCategory: preferredCategory ?? this.preferredCategory,
    );
  }
}

enum UserRole {
  donor,
  ngo,
  // Retained only for backwards compatibility with older documents.
  volunteer,
  // Retained only for backwards compatibility with existing admin accounts.
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.donor:
        return 'Donor';
      case UserRole.ngo:
        return 'NGO';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.donor:
        return Icons.favorite_rounded;
      case UserRole.ngo:
        return Icons.business_rounded;
      case UserRole.volunteer:
        return Icons.volunteer_activism_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}
