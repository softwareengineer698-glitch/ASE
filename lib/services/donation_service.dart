import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_model.dart';
import '../models/claim_model.dart';
import '../services/historical_data_service.dart';

class DonationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Create ────────────────────────────────────────────────────────────────

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
    DonationItemType itemType = DonationItemType.food,
    List<String> imagePublicIds = const [],
    double? latitude,
    double? longitude,
  }) async {
    final data = {
      'donorId': donorId,
      'title': title,
      'description': description,
      'category': category,
      'itemType': itemType.name,
      'quantity': quantity,
      'remainingQuantity': quantity,
      'unit': unit,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'imagePublicIds': imagePublicIds,
      'timestamp': FieldValue.serverTimestamp(),
      'expiryTime': expiryTime.toIso8601String(),
      'status': DonationStatus.available.name,
      'claimedBy': null,
      'claimedAt': null,
      'completedAt': null,
    };
    final ref = await _db.collection('donations').add(data);
    return ref.id;
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<DonationModel>> getAvailableDonations() {
    return _db
        .collection('donations')
        .where('status', whereIn: [
          DonationStatus.available.name,
          DonationStatus.partiallyClaimed.name,
        ])
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .where((doc) {
                final expiry = DateTime.tryParse(
                    doc.data()['expiryTime'] as String? ?? '');
                return expiry != null && expiry.isAfter(DateTime.now());
              })
              .map((doc) => DonationModel.fromMap(doc.data(), doc.id))
              .where((d) => d.remainingQuantity > 0)
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  /// Returns donations sorted by distance from [lat],[lng].
  Stream<List<DonationModel>> getNearbyDonations({
    required double lat,
    required double lng,
    double radiusKm = 20,
  }) {
    return getAvailableDonations().map((donations) {
      final withDistance = donations
          .where((d) => d.latitude != null && d.longitude != null)
          .map((d) =>
              MapEntry(d, _distanceKm(lat, lng, d.latitude!, d.longitude!)))
          .where((e) => e.value <= radiusKm)
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      return withDistance.map((e) => e.key).toList();
    });
  }

  Stream<List<DonationModel>> getDonorDonations(String donorId) {
    return _db
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => DonationModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<DonationModel>> getNGOClaimedDonations(String ngoId) {
    return _db
        .collection('donations')
        .where('claimedBy', isEqualTo: ngoId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => DonationModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<int> getAvailableDonationsCount() {
    return getAvailableDonations().map((donations) => donations.length);
  }

  // ── NGO Statistics ─────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> getNGOStatistics(String ngoId) {
    return _db
        .collection('donations')
        .where('claimedBy', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
      int pendingPickups = 0;
      double totalQuantityReceived = 0;

      for (var doc in snapshot.docs) {
        final donation = DonationModel.fromMap(doc.data(), doc.id);
        if (donation.status == DonationStatus.claimed) {
          pendingPickups++;
        }
        totalQuantityReceived += donation.quantity;
      }

      return {
        'pendingPickups': pendingPickups,
        'totalQuantityReceived': totalQuantityReceived,
        'totalClaims': snapshot.docs.length,
      };
    });
  }

  // ── Claim and Release Donations ────────────────────────────────────────────

  /// NGO claims a donation (full or partial)
  Future<void> claimDonation({
    required String donationId,
    required String claimantId,
    double? quantity, // If null, claims full remaining quantity
  }) async {
    final donRef = _db.collection('donations').doc(donationId);
    final donSnap = await donRef.get();

    if (!donSnap.exists) throw 'Donation not found';

    final don = DonationModel.fromMap(donSnap.data()!, donSnap.id);
    final claimQuantity = quantity ?? don.remainingQuantity;

    await submitClaim(
      donationId: donationId,
      claimantId: claimantId,
      requestedQuantity: claimQuantity,
    );
  }

  /// NGO releases a claimed donation (returns it to available pool)
  Future<void> releaseDonation(String donationId) async {
    final donRef = _db.collection('donations').doc(donationId);
    final donSnap = await donRef.get();

    if (!donSnap.exists) throw 'Donation not found';
    final don = DonationModel.fromMap(donSnap.data()!, donSnap.id);

    // Restore full quantity and set back to available
    await donRef.update({
      'remainingQuantity': don.quantity,
      'status': DonationStatus.available.name,
      'claimedBy': null,
      'claimedAt': null,
    });
  }

  // ── Partial Claim ─────────────────────────────────────────────────────────

  /// Submit a partial (or full) claim. Returns the new claim ID.
  /// No NGO verification check — phone OTP is sufficient.
  /// Prevents users from claiming their own donations.
  Future<String> submitClaim({
    required String donationId,
    required String claimantId,
    required double requestedQuantity,
  }) async {
    return _db.runTransaction<String>((tx) async {
      final donRef = _db.collection('donations').doc(donationId);
      final donSnap = await tx.get(donRef);

      if (!donSnap.exists) throw 'Donation not found';

      final don = DonationModel.fromMap(donSnap.data()!, donSnap.id);

      // ── Prevent self-claiming ──────────────────────────────────────────────
      if (don.donorId == claimantId) {
        throw 'You cannot claim your own donation';
      }

      final expiry = don.expiryTime;
      if (DateTime.now().isAfter(expiry)) {
        tx.update(donRef, {'status': DonationStatus.expired.name});
        throw 'This donation has expired';
      }
      if (don.remainingQuantity <= 0) throw 'No remaining quantity';
      if (requestedQuantity > don.remainingQuantity) {
        throw 'Requested quantity exceeds remaining (${don.remainingQuantity} ${don.unit})';
      }

      final newRemaining = don.remainingQuantity - requestedQuantity;
      final newStatus = newRemaining <= 0
          ? DonationStatus.claimed
          : DonationStatus.partiallyClaimed;

      tx.update(donRef, {
        'remainingQuantity': newRemaining,
        'status': newStatus.name,
        'claimedBy': claimantId, // last claimant for back-compat
        'claimedAt': FieldValue.serverTimestamp(),
      });

      final claimRef = _db.collection('claims').doc();
      tx.set(
          claimRef,
          ClaimModel(
            id: claimRef.id,
            donationId: donationId,
            claimantId: claimantId,
            donorId: don.donorId,
            claimedQuantity: requestedQuantity,
            unit: don.unit,
            createdAt: DateTime.now(),
          ).toMap());

      return claimRef.id;
    });
  }

  /// Donor accepts a claim — creates a chat room between donor and claimant.
  Future<void> acceptClaim(String claimId) async {
    final claimRef = _db.collection('claims').doc(claimId);
    final claimSnap = await claimRef.get();
    if (!claimSnap.exists) throw 'Claim not found';
    final claim = ClaimModel.fromMap(claimSnap.data()!, claimId);

    // Create chat room
    final roomRef = _db.collection('chat_rooms').doc();
    await roomRef.set({
      'participantIds': [claim.donorId, claim.claimantId],
      'claimId': claimId,
      'donationId': claim.donationId,
      'lastMessage': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'type': 'donor_recipient',
      'unreadCounts': {claim.donorId: 0, claim.claimantId: 0},
    });

    await claimRef.update({
      'status': ClaimStatus.accepted.name,
      'acceptedAt': FieldValue.serverTimestamp(),
      'chatRoomId': roomRef.id,
    });
  }

  Future<void> rejectClaim(String claimId) async {
    final claimRef = _db.collection('claims').doc(claimId);
    final claimSnap = await claimRef.get();
    if (!claimSnap.exists) return;
    final claim = ClaimModel.fromMap(claimSnap.data()!, claimId);

    await _db.runTransaction((tx) async {
      // Return quantity to donation
      final donRef = _db.collection('donations').doc(claim.donationId);
      final donSnap = await tx.get(donRef);
      if (donSnap.exists) {
        final don = DonationModel.fromMap(donSnap.data()!, donSnap.id);
        final restored = don.remainingQuantity + claim.claimedQuantity;
        final newStatus = restored >= don.quantity
            ? DonationStatus.available
            : DonationStatus.partiallyClaimed;
        tx.update(donRef, {
          'remainingQuantity': restored,
          'status': newStatus.name,
        });
      }
      tx.update(claimRef, {'status': ClaimStatus.rejected.name});
    });
  }

  /// Mark donation completed by donor after pickup
  Future<void> completeDonation(String donationId) async {
    await _db.collection('donations').doc(donationId).update({
      'status': DonationStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
    // Record outcome for historical trend analysis
    final snap = await _db.collection('donations').doc(donationId).get();
    if (snap.exists) {
      final donation = DonationModel.fromMap(snap.data()!, donationId);
      await HistoricalDataService().recordDonationOutcome(donation);
    }
  }

  Future<void> deleteDonation(String donationId) async {
    await _db.collection('donations').doc(donationId).delete();
  }

  /// Adds image URLs to an existing donation document after upload.
  Future<void> updateDonationImages(
    String donationId,
    List<String> urls, {
    List<String> publicIds = const [],
  }) async {
    await _db.collection('donations').doc(donationId).update({
      'imageUrls': urls,
      'imagePublicIds': publicIds,
    });
  }

  // ── Paginated queries ────────────────────────────────────────────────────
  // Default page size used by donor dashboard and nearby food screen.
  static const int defaultPageSize = 20;

  /// First page of available donations (status = available | partiallyClaimed,
  /// not expired). Returns up to [pageSize] items ordered newest-first.
  Future<_DonationPage> getAvailableDonationsPaged({
    int pageSize = defaultPageSize,
  }) async {
    // Avoid composite index by not using orderBy with whereIn — sort client-side
    final snap = await _db
        .collection('donations')
        .where('status', whereIn: [
          DonationStatus.available.name,
          DonationStatus.partiallyClaimed.name,
        ])
        .limit(pageSize * 2) // fetch extra to account for client-side filtering
        .get();

    final items = _filterValid(snap);
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final page = items.take(pageSize).toList();
    return _DonationPage(
      items: page,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: items.length >= pageSize,
    );
  }

  /// Subsequent pages — pass [lastDoc] from the previous [_DonationPage].
  Future<_DonationPage> getAvailableDonationsNextPage({
    required DocumentSnapshot lastDoc,
    int pageSize = defaultPageSize,
  }) async {
    // Avoid composite index — no orderBy with whereIn
    final snap = await _db
        .collection('donations')
        .where('status', whereIn: [
          DonationStatus.available.name,
          DonationStatus.partiallyClaimed.name,
        ])
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();

    final items = _filterValid(snap);
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _DonationPage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == pageSize,
    );
  }

  List<DonationModel> _filterValid(QuerySnapshot snap) {
    return snap.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final expiry =
              DateTime.tryParse((data['expiryTime'] as String?) ?? '');
          return expiry != null && expiry.isAfter(DateTime.now());
        })
        .map((doc) =>
            DonationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((d) => d.remainingQuantity > 0)
        .toList();
  }

  /// Paginated version of [getDonorDonations] — first page.
  Future<_DonationPage> getDonorDonationsPaged(
    String donorId, {
    int pageSize = defaultPageSize,
  }) async {
    // No orderBy to avoid requiring a composite Firestore index — sort client-side
    final snap = await _db
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .limit(pageSize)
        .get();

    final items = snap.docs
        .map((d) =>
            DonationModel.fromMap(d.data(), d.id))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return _DonationPage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == pageSize,
    );
  }

  /// Next page for [getDonorDonationsPaged].
  Future<_DonationPage> getDonorDonationsNextPage(
    String donorId, {
    required DocumentSnapshot lastDoc,
    int pageSize = defaultPageSize,
  }) async {
    final snap = await _db
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();

    final items = snap.docs
        .map((d) =>
            DonationModel.fromMap(d.data(), d.id))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return _DonationPage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == pageSize,
    );
  }

  // ── Claims streams ────────────────────────────────────────────────────────

  Stream<List<ClaimModel>> getClaimsForDonation(String donationId) {
    return _db
        .collection('claims')
        .where('donationId', isEqualTo: donationId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<ClaimModel>> getMyActiveClaims(String userId) {
    return _db
        .collection('claims')
        .where('claimantId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<ClaimModel>> getClaimsForDonor(String donorId) {
    return _db
        .collection('claims')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // ── Auto-expire & auto-relist ─────────────────────────────────────────────

  /// Expire overdue donations and auto-cancel timed-out claims.
  /// Alias for runExpiryAndRelistJob() for backward compatibility.
  Future<void> expireDonations() async {
    await runExpiryAndRelistJob();
  }

  /// Expire overdue donations and auto-cancel timed-out claims.
  Future<void> runExpiryAndRelistJob() async {
    final now = DateTime.now();

    // 1. Expire available/partially-claimed donations past expiry
    final expiredQuery = await _db.collection('donations').where('status',
        whereIn: [
          DonationStatus.available.name,
          DonationStatus.partiallyClaimed.name
        ]).get();

    for (final doc in expiredQuery.docs) {
      final expiry =
          DateTime.tryParse(doc.data()['expiryTime'] as String? ?? '');
      if (expiry != null && now.isAfter(expiry)) {
        await doc.reference.update({'status': DonationStatus.expired.name});
        // Record expired outcome for historical tracking
        final donation =
            DonationModel.fromMap(doc.data(), doc.id);
        await HistoricalDataService().recordDonationOutcome(
            donation.copyWith(status: DonationStatus.expired));
      }
    }

    // 2. Auto-cancel pending/accepted claims where donation expired or pickup
    // was not completed within the allowed window, then restore quantity.
    final staleClaims = await _db.collection('claims').where('status',
        whereIn: [ClaimStatus.pending.name, ClaimStatus.accepted.name]).get();

    for (final doc in staleClaims.docs) {
      final claim = ClaimModel.fromMap(doc.data(), doc.id);
      final donSnap =
          await _db.collection('donations').doc(claim.donationId).get();
      if (!donSnap.exists) continue;
      final don = DonationModel.fromMap(donSnap.data()!, donSnap.id);
      final acceptedTimedOut = claim.status == ClaimStatus.accepted &&
          claim.acceptedAt != null &&
          now.difference(claim.acceptedAt!).inHours >= 24 &&
          claim.pickedUpAt == null;
      final pendingTimedOut = claim.status == ClaimStatus.pending &&
          now.difference(claim.createdAt).inHours >= 24;
      if (don.isExpired ||
          don.status == DonationStatus.expired ||
          acceptedTimedOut ||
          pendingTimedOut) {
        await _db.runTransaction((tx) async {
          final freshDonSnap = await tx.get(donSnap.reference);
          if (!freshDonSnap.exists) return;
          final freshDon =
              DonationModel.fromMap(freshDonSnap.data()!, freshDonSnap.id);
          final restored = freshDon.remainingQuantity + claim.claimedQuantity;
          final clamped = restored > freshDon.quantity
              ? freshDon.quantity
              : restored;
          final newStatus = freshDon.isExpired
              ? DonationStatus.expired
              : clamped >= freshDon.quantity
                  ? DonationStatus.available
                  : DonationStatus.partiallyClaimed;
          tx.update(doc.reference, {
            'status': ClaimStatus.cancelled.name,
            'cancelledAt': Timestamp.fromDate(now),
          });
          tx.update(freshDonSnap.reference, {
            'remainingQuantity': clamped,
            'status': newStatus.name,
            if (newStatus == DonationStatus.available) 'claimedBy': null,
          });
        });
      }
    }
  }

  // ── Statistics ────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> getDonorStatistics(String donorId) {
    return _db
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snap) {
      final donations = snap.docs.map((d) => d.data()).toList();
      final total = donations.length;
      final available = donations
          .where((d) => d['status'] == DonationStatus.available.name)
          .length;
      final claimed = donations
          .where((d) =>
              d['status'] == DonationStatus.claimed.name ||
              d['status'] == DonationStatus.partiallyClaimed.name)
          .length;
      final completed = donations
          .where((d) => d['status'] == DonationStatus.completed.name)
          .length;
      final expired = donations
          .where((d) => d['status'] == DonationStatus.expired.name)
          .length;
      final totalSaved = donations
          .where((d) => d['status'] == DonationStatus.completed.name)
          .fold<double>(
              0, (acc, d) => acc + ((d['quantity'] as num?)?.toDouble() ?? 0));

      final categories = <String, int>{};
      for (final d in donations) {
        final c = d['category'] as String? ?? 'Other';
        categories[c] = (categories[c] ?? 0) + 1;
      }

      return {
        'totalDonations': total,
        'pendingDonations': available,
        'claimedDonations': claimed,
        'completedDonations': completed,
        'expiredDonations': expired,
        'totalQuantitySaved': totalSaved,
        'categoryCounts': categories,
      };
    });
  }

  // ── Leaderboards ──────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getDonorLeaderboard() {
    return _db
        .collection('donations')
        .where('status', isEqualTo: DonationStatus.completed.name)
        .snapshots()
        .asyncMap((snap) async {
      final stats = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        final id = d['donorId'] as String;
        stats.putIfAbsent(id, () => {'completed': 0, 'saved': 0.0});
        stats[id]!['completed']++;
        stats[id]!['saved'] += (d['quantity'] as num?)?.toDouble() ?? 0;
      }
      final result = <Map<String, dynamic>>[];
      for (final uid in stats.keys) {
        try {
          final u = await _db.collection('users').doc(uid).get();
          final saved = stats[uid]!['saved'] as double;
          result.add({
            'userId': uid,
            'name': u.data()?['userName'] ?? u.data()?['email'] ?? 'Unknown',
            'completedDonations': stats[uid]!['completed'],
            'foodSaved': saved,
            'peopleFed': (saved * 4).round(),
          });
        } catch (_) {}
      }
      result.sort((a, b) =>
          (b['foodSaved'] as double).compareTo(a['foodSaved'] as double));
      return result.take(10).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getNGOLeaderboard() {
    return getDonorLeaderboard(); // reuse same logic
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Haversine distance in km
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}

// ── Pagination value type ─────────────────────────────────────────────────

/// Holds one page of [DonationModel] results plus the cursor needed to
/// fetch the next page via [DonationService.getAvailableDonationsNextPage].
class _DonationPage {
  final List<DonationModel> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const _DonationPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });
}

/// Public alias so screens can reference the type without the leading _.
typedef DonationPage = _DonationPage;
