import 'dart:math';
import '../models/user_profile_model.dart';

class ProfileService {
  // Singleton pattern for global access
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Current user profile (in-memory storage)
  UserProfile? _currentProfile;
  
  // Listeners for profile updates
  final List<Function(UserProfile?)> _listeners = [];

  // Initialize with mock profile data
  void initializeMockProfile({UserRole role = UserRole.donor}) {
    if (_currentProfile == null) {
      _currentProfile = _createMockProfile(role);
      _notifyListeners();
    }
  }

  // Get current user profile
  UserProfile? getCurrentProfile() {
    return _currentProfile;
  }

  // Update user profile
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentProfile = updatedProfile.copyWith(updatedAt: DateTime.now());
      _notifyListeners();
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update specific profile fields
  Future<bool> updateProfileField({
    String? name,
    String? email,
    String? phone,
    String? organization,
    String? address,
    String? bio,
    String? profileImageUrl,
  }) async {
    if (_currentProfile == null) return false;

    final updatedProfile = _currentProfile!.copyWith(
      name: name,
      email: email,
      phone: phone,
      organization: organization,
      address: address,
      bio: bio,
      profileImageUrl: profileImageUrl,
    );

    return await updateProfile(updatedProfile);
  }

  // Switch user role (for demo purposes)
  Future<bool> switchRole(UserRole newRole) async {
    if (_currentProfile == null) return false;

    final updatedProfile = _currentProfile!.copyWith(
      role: newRole,
      organization: newRole == UserRole.ngo ? 'Sample NGO Organization' : null,
    );

    return await updateProfile(updatedProfile);
  }

  // Reset profile to default
  void resetProfile() {
    _currentProfile = null;
    _notifyListeners();
  }

  // Create new profile
  Future<bool> createProfile({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? organization,
    String? address,
    String? bio,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _currentProfile = UserProfile(
        id: _generateId(),
        name: name,
        email: email,
        phone: phone,
        role: role,
        organization: organization,
        address: address,
        bio: bio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _notifyListeners();
      return true;
    } catch (e) {
      print('Error creating profile: $e');
      return false;
    }
  }

  // Listen to profile changes
  void addListener(Function(UserProfile?) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(UserProfile?) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_currentProfile);
    }
  }

  // Create mock profile for demo
  UserProfile _createMockProfile(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return UserProfile(
          id: _generateId(),
          name: 'John Smith',
          email: 'john.smith@email.com',
          phone: '+1 (555) 123-4567',
          role: UserRole.donor,
          organization: 'Green Grocery Store',
          address: '123 Main Street, City, State 12345',
          bio: 'Passionate about reducing food waste and helping the community. Owner of Green Grocery Store.',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        );
      case UserRole.ngo:
        return UserProfile(
          id: _generateId(),
          name: 'Sarah Johnson',
          email: 'sarah@helpinghands.org',
          phone: '+1 (555) 987-6543',
          role: UserRole.ngo,
          organization: 'Helping Hands NGO',
          address: '456 Community Ave, City, State 12345',
          bio: 'Dedicated to fighting hunger and food insecurity in our community. Coordinator at Helping Hands NGO.',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
    }
  }

  // Helper methods
  String _generateId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Get profile statistics
  Map<String, dynamic> getProfileStats() {
    if (_currentProfile == null) return {};

    return {
      'isComplete': _currentProfile!.isComplete,
      'memberSince': _formatMemberSince(_currentProfile!.createdAt),
      'lastUpdated': _currentProfile!.updatedAt,
      'role': _currentProfile!.roleDisplayName,
    };
  }

  String _formatMemberSince(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  // Validation helpers
  bool isValidProfile(UserProfile profile) {
    return profile.validateName(profile.name) == null &&
           profile.validateEmail(profile.email) == null &&
           profile.validatePhone(profile.phone) == null &&
           profile.validateOrganization(profile.organization) == null;
  }

  // Demo mode helpers
  void loadDemoData(UserRole role) {
    _currentProfile = _createMockProfile(role);
    _notifyListeners();
  }

  void clearDemoData() {
    _currentProfile = null;
    _notifyListeners();
  }
}
