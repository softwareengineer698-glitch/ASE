import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Centralized service that fires Firestore-backed notifications for
/// every significant event in the app.  All methods are fire-and-forget
/// (errors are caught and printed so they never crash the caller).
class NotificationTriggerService {
  static final NotificationTriggerService _i =
      NotificationTriggerService._internal();
  factory NotificationTriggerService() => _i;
  NotificationTriggerService._internal();

  final _ns = NotificationService();
  final _db = FirebaseFirestore.instance;

  // ── helpers ────────────────────────────────────────────────────────────────

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _push(String userId, AppNotification n) async {
    try {
      await _ns.createRemoteNotificationForUser(userId: userId, notification: n);
    } catch (e) {
      debugPrint('Notification push error: $e');
    }
  }

  Future<String?> _userName(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final d = doc.data();
      return (d?['name'] ?? d?['userName'] ?? d?['organizationName'] ?? d?['email'])
          ?.toString();
    } catch (_) {
      return null;
    }
  }

  // ── 1. New food available (broadcast to every other user) ─────────────────

  Future<void> onNewDonationCreated({
    required String donorId,
    required String donorName,
    required String donationId,
    required String foodTitle,
    required String category,
    required double quantity,
    required String unit,
    required String location,
  }) async {
    try {
      final usersSnap = await _db.collection('users').get();
      for (final doc in usersSnap.docs) {
        if (doc.id == donorId) continue;
        await _push(
          doc.id,
          AppNotification(
            id: '${_id('new_food')}_${doc.id}',
            title: '🍎 New Food Available Nearby',
            message:
                '$donorName posted $quantity $unit of $category near $location.',
            type: NotificationType.surplusReported,
            priority: NotificationPriority.high,
            timestamp: DateTime.now(),
            actionData: 'donation_$donationId',
            relatedDonationId: donationId,
          ),
        );
      }
    } catch (e) {
      debugPrint('onNewDonationCreated error: $e');
    }
  }

  // ── 2. Food claimed — notify donor ────────────────────────────────────────

  Future<void> onFoodClaimed({
    required String donorId,
    required String claimantId,
    required String donationId,
    required String donationTitle,
    required double claimedQuantity,
    required String unit,
    required String claimId,
  }) async {
    final claimantName = await _userName(claimantId) ?? 'Someone';
    await _push(
      donorId,
      AppNotification(
        id: _id('claimed'),
        title: '📋 Your Donation Was Claimed',
        message:
            '$claimantName claimed $claimedQuantity $unit of "$donationTitle".',
        type: NotificationType.claimReceived,
        priority: NotificationPriority.high,
        timestamp: DateTime.now(),
        actionData: 'donation_$donationId',
        relatedDonationId: donationId,
      ),
    );
  }

  // ── 3. Claim accepted — notify claimant ───────────────────────────────────

  Future<void> onClaimAccepted({
    required String claimantId,
    required String donorId,
    required String donationId,
    required String donationTitle,
    required String chatRoomId,
  }) async {
    final donorName = await _userName(donorId) ?? 'The donor';
    await _push(
      claimantId,
      AppNotification(
        id: _id('claim_accepted'),
        title: '✅ Claim Accepted!',
        message:
            '$donorName accepted your claim for "$donationTitle". Open chat to coordinate pickup.',
        type: NotificationType.claimAccepted,
        priority: NotificationPriority.high,
        timestamp: DateTime.now(),
        actionData: 'chat_$chatRoomId',
        relatedDonationId: donationId,
        relatedChatRoomId: chatRoomId,
      ),
    );
  }

  // ── 4. Claim rejected — notify claimant ───────────────────────────────────

  Future<void> onClaimRejected({
    required String claimantId,
    required String donationId,
    required String donationTitle,
  }) async {
    await _push(
      claimantId,
      AppNotification(
        id: _id('claim_rejected'),
        title: '❌ Claim Not Approved',
        message:
            'Your claim for "$donationTitle" was not approved. Browse other available donations.',
        type: NotificationType.claimRejected,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now(),
        actionData: 'request_list',
        relatedDonationId: donationId,
      ),
    );
  }

  // ── 5. Pickup reminder — notify claimant ─────────────────────────────────

  Future<void> onPickupReminder({
    required String claimantId,
    required String donationId,
    required String donationTitle,
    required int hoursLeft,
  }) async {
    await _push(
      claimantId,
      AppNotification(
        id: '${_id('pickup_reminder')}_$donationId',
        title: '⏰ Pickup Reminder',
        message:
            'Only $hoursLeft hours left to pick up "$donationTitle". Please collect it soon!',
        type: NotificationType.pickupReminder,
        priority:
            hoursLeft <= 6 ? NotificationPriority.urgent : NotificationPriority.high,
        timestamp: DateTime.now(),
        actionData: 'donation_$donationId',
        relatedDonationId: donationId,
      ),
    );
  }

  // ── 6. Expiry reminder — notify donor ─────────────────────────────────────

  Future<void> onExpiryReminder({
    required String donorId,
    required String donationId,
    required String donationTitle,
    required int hoursLeft,
  }) async {
    await _push(
      donorId,
      AppNotification(
        id: '${_id('expiry_reminder')}_$donationId',
        title: '⚠️ Donation Expiring Soon',
        message:
            '"$donationTitle" will expire in $hoursLeft hours. It hasn\'t been fully claimed yet.',
        type: NotificationType.expiryReminder,
        priority:
            hoursLeft <= 6 ? NotificationPriority.urgent : NotificationPriority.high,
        timestamp: DateTime.now(),
        actionData: 'donation_$donationId',
        relatedDonationId: donationId,
      ),
    );
  }

  // ── 7. Donation completed — notify all parties ────────────────────────────

  Future<void> onDonationCompleted({
    required String donorId,
    required String claimantId,
    required String donationId,
    required String donationTitle,
  }) async {
    final donorName = await _userName(donorId) ?? 'The donor';
    // Notify claimant
    await _push(
      claimantId,
      AppNotification(
        id: '${_id('collected')}_claimant',
        title: '🎉 Pickup Completed!',
        message: '"$donationTitle" has been marked as completed by $donorName.',
        type: NotificationType.surplusCollected,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now(),
        actionData: 'donation_$donationId',
        relatedDonationId: donationId,
      ),
    );
    // Notify donor
    await _push(
      donorId,
      AppNotification(
        id: '${_id('collected')}_donor',
        title: '🎉 Donation Completed!',
        message: '"$donationTitle" has been successfully picked up. Thank you for donating!',
        type: NotificationType.surplusCollected,
        priority: NotificationPriority.medium,
        timestamp: DateTime.now(),
        actionData: 'donation_$donationId',
        relatedDonationId: donationId,
      ),
    );
  }

  // ── 8. New chat message — notify receiver ─────────────────────────────────

  Future<void> onNewChatMessage({
    required String senderId,
    required String receiverId,
    required String chatRoomId,
    required String messagePreview,
  }) async {
    // Don't notify sender
    if (senderId == receiverId) return;
    final senderName = await _userName(senderId) ?? 'Someone';
    await _push(
      receiverId,
      AppNotification(
        id: _id('message'),
        title: '💬 New Message from $senderName',
        message: messagePreview.length > 80
            ? '${messagePreview.substring(0, 80)}...'
            : messagePreview,
        type: NotificationType.newMessage,
        priority: NotificationPriority.high,
        timestamp: DateTime.now(),
        actionData: 'chat_$chatRoomId',
        relatedChatRoomId: chatRoomId,
        relatedUserName: senderName,
      ),
    );
  }

  // ── Expiry/pickup background checker ──────────────────────────────────────

  /// Called by DonationExpiryService to send reminders for donations
  /// expiring within 12 or 6 hours that haven't been reminded yet.
  Future<void> sendExpiryAndPickupReminders() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final now = DateTime.now();
      final snap = await _db.collection('donations').where('status',
          whereIn: ['available', 'partiallyClaimed', 'claimed']).get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final expiryStr = data['expiryTime'] as String?;
        if (expiryStr == null) continue;
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry == null || expiry.isBefore(now)) continue;

        final hoursLeft = expiry.difference(now).inHours;
        final donorId = data['donorId'] as String? ?? '';
        final title = data['title'] as String? ?? 'Donation';
        final donationId = doc.id;

        // Only remind at 12h and 6h thresholds — use a sent-flag in Firestore
        // to avoid duplicate reminders.
        final threshold = hoursLeft <= 6 ? 6 : (hoursLeft <= 12 ? 12 : 0);
        if (threshold == 0) continue;

        final flagKey = 'reminderSent_${threshold}h';
        if (data[flagKey] == true) continue;

        // Mark flag first to avoid double-send
        await doc.reference.update({flagKey: true});

        // Expiry reminder → donor
        if (donorId.isNotEmpty) {
          await onExpiryReminder(
            donorId: donorId,
            donationId: donationId,
            donationTitle: title,
            hoursLeft: hoursLeft,
          );
        }

        // Pickup reminder → claimant (if claimed)
        final claimedBy = data['claimedBy'] as String?;
        if (claimedBy != null &&
            claimedBy.isNotEmpty &&
            (data['status'] == 'claimed' || data['status'] == 'partiallyClaimed')) {
          await onPickupReminder(
            claimantId: claimedBy,
            donationId: donationId,
            donationTitle: title,
            hoursLeft: hoursLeft,
          );
        }
      }
    } catch (e) {
      debugPrint('sendExpiryAndPickupReminders error: $e');
    }
  }
}
