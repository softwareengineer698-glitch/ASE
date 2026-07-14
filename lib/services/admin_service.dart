import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream all users
  Stream<List<UserModel>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Stream all donors
  Stream<List<UserModel>> streamAllDonors() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Stream all NGOs (all NGOs are automatically verified - verification layer removed)
  Stream<List<UserModel>> streamAllNGOs() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'ngo')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Delete a user account (Donor or NGO)
  Future<void> deleteUser(String uid) async {
    // Delete user document from Firestore
    await _firestore.collection('users').doc(uid).delete();

    // Also clean up related data
    // Delete user's donations
    final donationDocs = await _firestore
        .collection('donations')
        .where('donorId', isEqualTo: uid)
        .get();
    for (final doc in donationDocs.docs) {
      await doc.reference.delete();
    }

    // Delete user's surplus reports
    final surplusDocs = await _firestore
        .collection('surplus_reports')
        .where('donorId', isEqualTo: uid)
        .get();
    for (final doc in surplusDocs.docs) {
      await doc.reference.delete();
    }

    // Delete user's NGO requests
    final ngoRequests = await _firestore
        .collection('ngo_requests')
        .where('ngoId', isEqualTo: uid)
        .get();
    for (final doc in ngoRequests.docs) {
      await doc.reference.delete();
    }

    // Delete volunteer profile if exists
    try {
      await _firestore.collection('volunteers').doc(uid).delete();
    } catch (_) {}
  }

  // System stats summary (real-time)
  Stream<Map<String, int>> streamSystemStats() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final int totalUsers = snapshot.docs.length;
      // All NGOs are now automatically verified - no pending verification
      final int activeNGOs = snapshot.docs
          .where((doc) => doc.data()['role'] == 'ngo')
          .length;
      final int donors =
          snapshot.docs.where((doc) => doc.data()['role'] == 'donor').length;
      final int volunteers = snapshot.docs
          .where((doc) => doc.data()['role'] == 'volunteer')
          .length;

      return {
        'totalUsers': totalUsers,
        'activeNGOs': activeNGOs,
        'donors': donors,
        'volunteers': volunteers,
      };
    });
  }
}
