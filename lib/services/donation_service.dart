import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_model.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new donation
  Future<String> createDonation({
    required String donorId,
    required String title,
    required String description,
    required String category,
    required double quantity,
    required String unit,
    required String location,
    required List<String> imageUrls,
    required DateTime expiryTime,
  }) async {
    try {
      final donationData = {
        'donorId': donorId,
        'title': title,
        'description': description,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'location': location,
        'imageUrls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'expiryTime': expiryTime.toIso8601String(),
        'status': 'available', // available, claimed, expired, completed
        'claimedBy': null,
        'claimedAt': null,
        'completedAt': null,
      };

      final docRef = await _firestore.collection('donations').add(donationData);
      return docRef.id;
    } catch (e) {
      throw 'Failed to create donation: $e';
    }
  }

  // Get available donations for NGOs (real-time stream)
  Stream<List<DonationModel>> getAvailableDonations() {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final expiryTime = DateTime.parse(data['expiryTime'] as String);
            return expiryTime.isAfter(DateTime.now());
          })
          .map((doc) => DonationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by timestamp (newest first)
      donations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return donations;
    });
  }

  // Get donations for a specific donor (real-time stream)
  Stream<List<DonationModel>> getDonorDonations(String donorId) {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by timestamp (newest first)
      donations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return donations;
    });
  }

  // Get claimed donations for an NGO (real-time stream)
  Stream<List<DonationModel>> getNGOClaimedDonations(String ngoId) {
    return _firestore
        .collection('donations')
        .where('claimedBy', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by timestamp (newest first)
      donations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return donations;
    });
  }

  // Claim a donation (NGO claims it) - with proper validation
  Future<void> claimDonation(String donationId, String ngoId) async {
    try {
      // First check if donation is still available
      final donationDoc =
          await _firestore.collection('donations').doc(donationId).get();

      if (!donationDoc.exists) {
        throw 'Donation not found';
      }

      final donationData = donationDoc.data()!;
      final currentStatus = donationData['status'] as String?;

      if (currentStatus != 'available') {
        throw 'Donation is no longer available';
      }

      // Check expiry time
      final expiryTime = DateTime.parse(donationData['expiryTime'] as String);
      if (DateTime.now().isAfter(expiryTime)) {
        // Auto-expire if past expiry time
        await donationDoc.reference.update({'status': 'expired'});
        throw 'Donation has expired';
      }

      // Use a transaction to ensure atomic update
      await _firestore.runTransaction((transaction) async {
        final freshDoc = await transaction.get(donationDoc.reference);

        if (!freshDoc.exists) {
          throw Exception('Donation not found');
        }

        final freshData = freshDoc.data()!;
        final freshStatus = freshData['status'] as String?;

        if (freshStatus != 'available') {
          throw Exception('Donation was just claimed by another NGO');
        }

        // Update the donation
        transaction.update(donationDoc.reference, {
          'status': 'claimed',
          'claimedBy': ngoId,
          'claimedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw 'Failed to claim donation: $e';
    }
  }

  // Complete a donation (Donor marks it as completed)
  Future<void> completeDonation(String donationId) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to complete donation: $e';
    }
  }

  // Auto-expire donations (should be called periodically or via cloud functions)
  Future<void> expireDonations() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .where('expiryTime', isLessThan: now.toIso8601String())
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'status': 'expired'});
      }
    } catch (e) {
      throw 'Failed to expire donations: $e';
    }
  }

  // Get donor statistics (real-time)
  Stream<Map<String, dynamic>> getDonorStatistics(String donorId) {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs.map((doc) => doc.data()).toList();

      final totalDonations = donations.length;
      final pendingDonations =
          donations.where((d) => d['status'] == 'available').length;
      final claimedDonations =
          donations.where((d) => d['status'] == 'claimed').length;
      final completedDonations =
          donations.where((d) => d['status'] == 'completed').length;
      final expiredDonations =
          donations.where((d) => d['status'] == 'expired').length;

      // Calculate total quantity saved
      final totalQuantitySaved = donations
          .where((d) => d['status'] == 'completed')
          .fold<double>(0, (sum, d) => sum + (d['quantity'] as num).toDouble());

      // Get most recent donation
      final recentDonation = donations.isNotEmpty
          ? donations.reduce((a, b) => (a['timestamp'] as Timestamp)
                      .compareTo(b['timestamp'] as Timestamp) >
                  0
              ? a
              : b)
          : null;

      // Count by categories
      final categoryCounts = <String, int>{};
      for (final donation in donations) {
        final category = donation['category'] as String? ?? 'Other';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return {
        'totalDonations': totalDonations,
        'pendingDonations': pendingDonations,
        'claimedDonations': claimedDonations,
        'completedDonations': completedDonations,
        'expiredDonations': expiredDonations,
        'totalQuantitySaved': totalQuantitySaved,
        'recentDonation': recentDonation,
        'categoryCounts': categoryCounts,
      };
    });
  }

  // Get NGO statistics (real-time)
  Stream<Map<String, dynamic>> getNGOStatistics(String ngoId) {
    return _firestore
        .collection('donations')
        .where('claimedBy', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs.map((doc) => doc.data()).toList();

      final claimedDonations = donations.length;
      final completedPickups =
          donations.where((d) => d['status'] == 'completed').length;
      final pendingPickups =
          donations.where((d) => d['status'] == 'claimed').length;

      // Calculate total quantity received
      final totalQuantityReceived = donations
          .where((d) => d['status'] == 'completed')
          .fold<double>(0, (sum, d) => sum + (d['quantity'] as num).toDouble());

      // Get most recent activity
      final recentActivity = donations.isNotEmpty
          ? donations.reduce((a, b) {
              final aTime = a['claimedAt'] as Timestamp?;
              final bTime = b['claimedAt'] as Timestamp? ?? Timestamp.now();
              final comparison = aTime?.compareTo(bTime) ?? 1;
              return comparison > 0 ? a : b;
            })
          : null;

      return {
        'claimedDonations': claimedDonations,
        'completedPickups': completedPickups,
        'pendingPickups': pendingPickups,
        'totalQuantityReceived': totalQuantityReceived,
        'recentActivity': recentActivity,
      };
    });
  }

  // Get available donations count for NGOs
  Stream<int> getAvailableDonationsCount() {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final expiryTime = DateTime.parse(data['expiryTime'] as String);
        return expiryTime.isAfter(DateTime.now());
      }).length;
    });
  }

  // Get leaderboard data for donors
  Stream<List<Map<String, dynamic>>> getDonorLeaderboard() {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .asyncMap((donationsSnapshot) async {
      final leaderboardData = <Map<String, dynamic>>[];
      final donorStats = <String, Map<String, dynamic>>{};

      // Aggregate donation data by donor
      for (final donationDoc in donationsSnapshot.docs) {
        final donationData = donationDoc.data();
        final donorId = donationData['donorId'] as String;

        if (!donorStats.containsKey(donorId)) {
          donorStats[donorId] = {
            'completedDonations': 0,
            'foodSaved': 0.0,
          };
        }

        donorStats[donorId]!['completedDonations']++;
        donorStats[donorId]!['foodSaved'] +=
            (donationData['quantity'] as num).toDouble();
      }

      // Get user information for each donor
      for (final donorId in donorStats.keys) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(donorId).get();
          final userData = userDoc.data();
          final stats = donorStats[donorId]!;
          final foodSaved = stats['foodSaved'] as double;
          final peopleFed = (foodSaved * 4).round();

          leaderboardData.add({
            'userId': donorId,
            'email': userData?['email'] ?? donorId,
            'name': userData?['name'] ?? userData?['email'] ?? 'Unknown',
            'completedDonations': stats['completedDonations'],
            'foodSaved': foodSaved,
            'peopleFed': peopleFed,
            'totalQuantity': foodSaved,
          });
        } catch (e) {
          // User not found, skip
        }
      }

      // Sort by food saved (descending)
      leaderboardData.sort((a, b) =>
          (b['foodSaved'] as double).compareTo(a['foodSaved'] as double));

      return leaderboardData.take(10).toList(); // Top 10
    });
  }

  // Delete a donation permanently (for donors)
  Future<void> deleteDonation(String donationId) async {
    try {
      await _firestore.collection('donations').doc(donationId).delete();
    } catch (e) {
      throw 'Failed to delete donation: $e';
    }
  }

  // Release a claimed donation back to available (for NGOs)
  Future<void> releaseDonation(String donationId) async {
    try {
      await _firestore.collection('donations').doc(donationId).update({
        'status': 'available',
        'claimedBy': null,
        'claimedAt': null,
      });
    } catch (e) {
      throw 'Failed to release donation: $e';
    }
  }

  // Get leaderboard data for NGOs
  Stream<List<Map<String, dynamic>>> getNGOLeaderboard() {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .asyncMap((donationsSnapshot) async {
      final leaderboardData = <Map<String, dynamic>>[];
      final ngoStats = <String, Map<String, dynamic>>{};

      // Aggregate donation data by NGO
      for (final donationDoc in donationsSnapshot.docs) {
        final donationData = donationDoc.data();
        final ngoId = donationData['claimedBy'] as String?;

        if (ngoId != null) {
          if (!ngoStats.containsKey(ngoId)) {
            ngoStats[ngoId] = {
              'completedPickups': 0,
              'foodReceived': 0.0,
            };
          }

          ngoStats[ngoId]!['completedPickups']++;
          ngoStats[ngoId]!['foodReceived'] +=
              (donationData['quantity'] as num).toDouble();
        }
      }

      // Get user information for each NGO
      for (final ngoId in ngoStats.keys) {
        try {
          final userDoc = await _firestore.collection('users').doc(ngoId).get();
          final userData = userDoc.data();
          final stats = ngoStats[ngoId]!;
          final foodReceived = stats['foodReceived'] as double;
          final peopleHelped = (foodReceived * 4).round();

          leaderboardData.add({
            'userId': ngoId,
            'email': userData?['email'] ?? ngoId,
            'name': userData?['name'] ?? userData?['email'] ?? 'Unknown',
            'completedPickups': stats['completedPickups'],
            'foodReceived': foodReceived,
            'peopleHelped': peopleHelped,
            'totalQuantity': foodReceived,
          });
        } catch (e) {
          // User not found, skip
        }
      }

      // Sort by completed pickups (descending)
      leaderboardData.sort((a, b) => (b['completedPickups'] as int)
          .compareTo(a['completedPickups'] as int));

      return leaderboardData.take(10).toList(); // Top 10
    });
  }
}
