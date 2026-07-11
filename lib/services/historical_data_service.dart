import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../models/forecast_model.dart';

/// Records actual donation outcomes to `donations_history` in Firestore.
///
/// This collection feeds the ForecastService with real historical data so
/// trend analysis is data-driven rather than fully simulated.
///
/// Schema (additive-only, backward-compatible):
///   donations_history/{autoId}  →  DonationHistoryRecord.toMap()
class HistoricalDataService {
  static final HistoricalDataService _instance =
      HistoricalDataService._internal();
  factory HistoricalDataService() => _instance;
  HistoricalDataService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'donations_history';

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Call when a donation is marked completed or expired so the outcome is
  /// recorded permanently for future trend analysis.
  Future<void> recordDonationOutcome(DonationModel donation) async {
    try {
      final outcome = _outcomeFrom(donation.status);
      final claimedQty =
          donation.quantity - donation.remainingQuantity;

      final record = DonationHistoryRecord(
        id: '', // Firestore auto-ID
        donorId: donation.donorId,
        category: donation.category,
        itemType: donation.itemType.name,
        actualQuantity: donation.quantity,
        claimedQuantity: claimedQty,
        remainingQuantity: donation.remainingQuantity,
        postedAt: donation.timestamp,
        completedAt: donation.completedAt ?? DateTime.now(),
        outcome: outcome,
      );

      await _db.collection(_collection).add(record.toMap());
    } catch (e) {
      // Historical logging is non-critical — never crash the app
      debugPrint('HistoricalDataService.recordDonationOutcome error: $e');
    }
  }

  String _outcomeFrom(DonationStatus status) {
    switch (status) {
      case DonationStatus.completed:
        return 'completed';
      case DonationStatus.expired:
        return 'expired';
      case DonationStatus.partiallyClaimed:
        return 'partial';
      default:
        return status.name;
    }
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the last [days] days of history for [donorId].
  /// Used by ForecastService to adjust simulated predictions with real trends.
  Future<List<DonationHistoryRecord>> getRecentHistory({
    required String donorId,
    int days = 30,
  }) async {
    try {
      final since = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: days)),
      );

      final snap = await _db
          .collection(_collection)
          .where('donorId', isEqualTo: donorId)
          .where('postedAt', isGreaterThanOrEqualTo: since)
          .orderBy('postedAt', descending: true)
          .limit(200)
          .get();

      return snap.docs
          .map((d) => DonationHistoryRecord.fromMap(
              d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('HistoricalDataService.getRecentHistory error: $e');
      return [];
    }
  }

  /// Returns aggregate stats from history for insight generation.
  ///   - avgDailyQuantity: average kg donated per day
  ///   - completionRate: fraction of donations that were fully claimed
  ///   - topCategory: category donated most often
  Future<Map<String, dynamic>> getAggregateStats(String donorId) async {
    final records = await getRecentHistory(donorId: donorId, days: 90);
    if (records.isEmpty) {
      return {
        'avgDailyQuantity': 0.0,
        'completionRate': 0.0,
        'topCategory': 'Food',
        'totalRecords': 0,
      };
    }

    final totalQty =
        records.fold<double>(0, (s, r) => s + r.actualQuantity);
    final completed =
        records.where((r) => r.outcome == 'completed').length;
    final categoryCount = <String, int>{};
    for (final r in records) {
      categoryCount[r.category] = (categoryCount[r.category] ?? 0) + 1;
    }
    final topCat = categoryCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return {
      'avgDailyQuantity': totalQty / 90,
      'completionRate': completed / records.length,
      'topCategory': topCat,
      'totalRecords': records.length,
    };
  }
}
