enum UserRole {
  donor,
  ngo,
}

class UserProfile {
  final String id;
  String name;
  String email;
  String phone;
  UserRole role;
  String? organization; // For NGOs
  String? address;
  String? bio;
  String? profileImageUrl;
  final DateTime createdAt;
  DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.organization,
    this.address,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to map for future database integration
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString(),
      'organization': organization,
      'address': address,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from map for future database integration
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => UserRole.donor,
      ),
      organization: map['organization'],
      address: map['address'],
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Copy with method for updates
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? organization,
    String? address,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  String get roleDisplayName {
    switch (role) {
      case UserRole.donor:
        return 'Food Donor';
      case UserRole.ngo:
        return 'NGO Partner';
    }
  }

  String get displayName {
    if (organization != null && organization!.isNotEmpty) {
      return '$name ($organization)';
    }
    return name;
  }

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  bool get isComplete {
    return name.isNotEmpty && 
           email.isNotEmpty && 
           phone.isNotEmpty &&
           (role == UserRole.donor || (organization != null && organization!.isNotEmpty));
  }

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? validateOrganization(String? value) {
    if (role == UserRole.ngo && (value == null || value.trim().isEmpty)) {
      return 'Organization name is required for NGOs';
    }
    return null;
  }
}
