import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';

class FirestoreProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user profile
  Future<void> saveProfile(ProfileModel profile) async {
    try {
      await _firestore
          .collection('profiles')
          .doc(profile.userId)
          .set(profile.toMap());
    } catch (e) {
      throw 'Failed to save profile: $e';
    }
  }

  // Get user profile
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('profiles')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return ProfileModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get profile: $e';
    }
  }

  // Stream user profile for real-time updates
  Stream<ProfileModel?> getProfileStream(String userId) {
    return _firestore
        .collection('profiles')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return ProfileModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // Update specific profile fields
  Future<void> updateProfileFields(String userId, Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore
          .collection('profiles')
          .doc(userId)
          .update(fields);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Delete user profile
  Future<void> deleteProfile(String userId) async {
    try {
      await _firestore
          .collection('profiles')
          .doc(userId)
          .delete();
    } catch (e) {
      throw 'Failed to delete profile: $e';
    }
  }

  // Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final doc = await _firestore
          .collection('profiles')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
