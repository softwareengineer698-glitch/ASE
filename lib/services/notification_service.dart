import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/ngo/surplus_list_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/request/my_requests_screen.dart';
import '../screens/request/request_list_screen.dart';

class NotificationService {
  // Singleton pattern for global access
  static final NotificationService _instance = NotificationService._internal();
  static const String _storageKey = 'foodbridge_notifications_v1';
  static const int _maxStoredNotifications = 200;

  factory NotificationService() => _instance;
  NotificationService._internal();

  // In-memory storage (will be replaced with Firebase later)
  final List<AppNotification> _notifications = [];

  // Listeners for real-time updates
  final List<Function(List<AppNotification>)> _listeners = [];

  // Current context for showing snackbars (set by main app)
  BuildContext? _currentContext;
  bool _storageLoaded = false;
  bool _fcmInitialized = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _remoteNotificationsSubscription;
  String? _remoteNotificationsUserId;

  // ── FCM ────────────────────────────────────────────────────────────────────

  Future<void> ensureReady() async {
    await _ensureLoaded();
    await _ensureRemoteSync();
  }

  /// Call once after Firebase is ready and the user is signed in.
  /// Registers/refreshes the FCM token and sets up foreground + tap handlers.
  Future<void> initializeFCM() async {
    await _ensureLoaded();
    await _ensureRemoteSync();
    final messaging = FirebaseMessaging.instance;

    if (_fcmInitialized) {
      await _saveFcmToken(await messaging.getToken());
      return;
    }
    _fcmInitialized = true;

    // Request permission (iOS / web)
    await messaging.requestPermission();

    // Register token
    await _saveFcmToken(await messaging.getToken());

    // Refresh token when it rotates
    messaging.onTokenRefresh.listen(_saveFcmToken);

    // Foreground messages → feed into existing in-app system
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App opened from a notification tap (background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Check if app was launched via a notification
    final initial = await messaging.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _ingestRemoteMessage(message, showInApp: false);
  }

  Future<void> _saveFcmToken(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token, 'notificationsEnabled': true});
    } catch (_) {
      // Field may not exist yet on older documents — use set with merge
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmToken': token, 'notificationsEnabled': true},
          SetOptions(merge: true));
    }
  }

  /// Call when the user toggles notifications on/off in settings.
  /// Persists the [enabled] flag to the user document so Cloud Functions
  /// respect the opt-out preference server-side.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'notificationsEnabled': enabled}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to persist notification preference: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) async {
    await _ingestRemoteMessage(message, showInApp: true);
  }

  void _onNotificationTap(RemoteMessage message) async {
    final notification = await _ingestRemoteMessage(message, showInApp: false);
    if (notification != null) {
      await handleNotificationTap(notification);
    }
  }

  NotificationType _parseType(String? v) {
    if (v == null) return NotificationType.general;
    return NotificationType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => NotificationType.general,
    );
  }

  NotificationPriority _parsePriority(String? v) {
    if (v == null) return NotificationPriority.medium;
    return NotificationPriority.values.firstWhere(
      (e) => e.name == v,
      orElse: () => NotificationPriority.medium,
    );
  }

  Future<AppNotification?> _ingestRemoteMessage(
    RemoteMessage message, {
    required bool showInApp,
  }) async {
    await _ensureLoaded();
    final notification = _notificationFromMessage(message);
    await _upsertNotification(notification);
    if (showInApp) {
      _showInAppNotification(notification);
    }
    return notification;
  }

  AppNotification _notificationFromMessage(RemoteMessage message) {
    final data = message.data;
    final chatRoomId = _cleanValue(data['chatRoomId']);
    final actionData = _cleanValue(data['actionData']) ??
        (chatRoomId != null ? 'chat_$chatRoomId' : null);

    return AppNotification(
      id: _cleanValue(data['notificationId']) ?? _generateId(),
      title: message.notification?.title ??
          _cleanValue(data['title']) ??
          'FoodBridge',
      message: message.notification?.body ?? _cleanValue(data['body']) ?? '',
      type: _parseType(_cleanValue(data['type'])),
      priority: _parsePriority(_cleanValue(data['priority'])),
      timestamp: DateTime.now(),
      actionData: actionData,
      relatedDonationId: _cleanValue(data['donationId']),
      relatedRequestId: _cleanValue(data['requestId']),
      relatedChatRoomId: chatRoomId,
      relatedUserName:
          _cleanValue(data['otherUserName']) ?? _cleanValue(data['senderName']),
    );
  }

  String? _cleanValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _ensureLoaded() async {
    if (_storageLoaded) return;
    _storageLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const [];
    _notifications
      ..clear()
      ..addAll(
        rawItems.map((item) {
          try {
            return AppNotification.fromMap(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        }).whereType<AppNotification>(),
      );
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _ensureRemoteSync() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await _remoteNotificationsSubscription?.cancel();
      _remoteNotificationsSubscription = null;
      _remoteNotificationsUserId = null;
      return;
    }

    if (_remoteNotificationsSubscription != null &&
        _remoteNotificationsUserId == uid) {
      return;
    }

    await _remoteNotificationsSubscription?.cancel();
    _remoteNotificationsUserId = uid;
    _remoteNotificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final notification = _notificationFromFirestore(doc);
        await _upsertNotification(notification);
      }
    });
  }

  AppNotification _notificationFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppNotification.fromMap({
      ...data,
      'id': data['id'] ?? doc.id,
      'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
    });
  }

  Future<void> _persistNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _notifications.take(_maxStoredNotifications).toList();
    await prefs.setStringList(
      _storageKey,
      trimmed.map((n) => jsonEncode(n.toMap())).toList(),
    );
  }

  Future<void> _upsertNotification(AppNotification notification) async {
    final existingIndex =
        _notifications.indexWhere((item) => item.id == notification.id);
    if (existingIndex >= 0) {
      final existing = _notifications.removeAt(existingIndex);
      notification = notification.copyWith(isRead: existing.isRead);
    }
    _notifications.insert(0, notification);
    await _persistNotifications();
    _notifyListeners();
  }

  // Initialize with some mock notifications
  void initializeMockData() {
    if (_notifications.isEmpty) {
      _notifications.addAll([
        AppNotification(
          id: _generateId(),
          title: 'Welcome to FoodBridge!',
          message:
              'Start reducing food waste by connecting with your community.',
          type: NotificationType.general,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AppNotification(
          id: _generateId(),
          title: 'New Surplus Available',
          message:
              'Fresh vegetables available for pickup from Green Grocery Store.',
          type: NotificationType.surplusReported,
          priority: NotificationPriority.high,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ]);
      _persistNotifications();
      _notifyListeners();
    }
  }

  // Set current context for showing UI notifications
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  // Get all notifications
  List<AppNotification> getAllNotifications() {
    final items = List<AppNotification>.from(_notifications);
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(items);
  }

  // Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  // Add new notification
  Future<void> addNotification(AppNotification notification) async {
    await _ensureLoaded();
    await _ensureRemoteSync();
    await _upsertNotification(notification);

    // Show in-app notification if context is available
    _showInAppNotification(notification);

    // Simulate push notification (placeholder for Firebase)
    _simulatePushNotification(notification);
  }

  // ──────────────────────────────────────
  // NOTIFICATION METHODS
  // ──────────────────────────────────────

  // Create and send surplus reported notification
  Future<void> notifySurplusReported({
    required String donorName,
    required String foodType,
    required int quantity,
    String? donationId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'New Surplus Available! 🍎',
      message:
          '$donorName has reported $quantity units of $foodType. Check it out!',
      type: NotificationType.surplusReported,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'surplus_list',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send surplus accepted notification
  Future<void> notifySurplusAccepted({
    required String ngoName,
    required String foodType,
    required String donorName,
    String? donationId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Surplus Accepted! ✅',
      message:
          '$ngoName has accepted your $foodType donation. They will coordinate pickup soon.',
      type: NotificationType.surplusAccepted,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'donor_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send surplus collected notification
  Future<void> notifySurplusCollected({
    required String foodType,
    required String ngoName,
    String? donationId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Surplus Collected! 🎉',
      message:
          'Your $foodType donation has been successfully collected by $ngoName. Thank you for reducing food waste!',
      type: NotificationType.surplusCollected,
      timestamp: DateTime.now(),
      actionData: 'donor_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send claim received notification (for donors)
  Future<void> notifyClaimReceived({
    required String ngoName,
    required String foodType,
    required String donorName,
    String? donationId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'New Claim Request! 📋',
      message:
          '$ngoName wants to claim your $foodType donation. Review and accept the request.',
      type: NotificationType.claimReceived,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'donor_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send claim accepted notification (for NGOs)
  Future<void> notifyClaimAccepted({
    required String donorName,
    required String foodType,
    String? donationId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Claim Approved! ✅',
      message:
          '$donorName has approved your claim for $foodType. Coordinate pickup details.',
      type: NotificationType.claimAccepted,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'ngo_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send claim rejected notification
  Future<void> notifyClaimRejected({
    required String donorName,
    required String foodType,
    required String rejectionReason,
    String? donationId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Claim Not Approved 😔',
      message:
          'Your claim for $foodType was not approved. Reason: $rejectionReason',
      type: NotificationType.claimRejected,
      timestamp: DateTime.now(),
      actionData: 'ngo_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send pickup reminder notification
  Future<void> notifyPickupReminder({
    required String foodType,
    required String donorName,
    required DateTime pickupDeadline,
    String? donationId,
  }) async {
    final hoursLeft = pickupDeadline.difference(DateTime.now()).inHours;
    final notification = AppNotification(
      id: _generateId(),
      title: 'Pickup Reminder ⏰',
      message:
          'Pick up $foodType from $donorName within $hoursLeft hours to prevent waste!',
      type: NotificationType.pickupReminder,
      priority: hoursLeft < 6
          ? NotificationPriority.urgent
          : NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'ngo_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send expiry reminder notification
  Future<void> notifyExpiryReminder({
    required String foodType,
    required DateTime expiryDate,
    String? donationId,
  }) async {
    final hoursLeft = expiryDate.difference(DateTime.now()).inHours;
    final notification = AppNotification(
      id: _generateId(),
      title: 'Food Expiring Soon! ⚠️',
      message:
          '$foodType will expire in $hoursLeft hours. Coordinate immediate pickup.',
      type: NotificationType.expiryReminder,
      priority: hoursLeft < 12
          ? NotificationPriority.urgent
          : NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'ngo_dashboard',
      relatedDonationId: donationId,
    );

    await addNotification(notification);
  }

  // Create and send request fulfilled notification
  Future<void> notifyRequestFulfilled({
    required String requestTitle,
    required String fulfilledByDonor,
    String? requestId,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Request Fulfilled! 🎁',
      message:
          '$fulfilledByDonor has provided the $requestTitle you requested.',
      type: NotificationType.requestFulfilled,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'my_requests',
      relatedRequestId: requestId,
    );

    await addNotification(notification);
  }

  // Create and send request created notification (for donors to see)
  Future<void> notifyRequestCreated({
    required String requestTitle,
    required String requestedByNGO,
    int? quantity,
    String? requestId,
  }) async {
    final message = quantity != null
        ? '$requestedByNGO needs $quantity units of $requestTitle'
        : '$requestedByNGO is looking for $requestTitle';

    final notification = AppNotification(
      id: _generateId(),
      title: 'New Food Request 📋',
      message: message,
      type: NotificationType.requestCreated,
      timestamp: DateTime.now(),
      actionData: 'request_list',
      relatedRequestId: requestId,
    );

    await addNotification(notification);
  }

  // ──────────────────────────────────────
  // UTILITY METHODS
  // ──────────────────────────────────────

  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      throw Exception('Notification not found');
    }

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _notifyListeners();
    _persistNotifications();
  }

  // Public method to show in-app notifications
  void showInAppNotification(String title, String message,
      {NotificationType? type}) {
    final notification = AppNotification(
      id: _generateId(),
      title: title,
      message: message,
      type: type ?? NotificationType.general,
      timestamp: DateTime.now(),
    );

    addNotification(notification);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _persistNotifications();
    _notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _persistNotifications();
    _notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _persistNotifications();
    _notifyListeners();
  }

  // Get notification count
  int get totalCount => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Listen to changes
  void addListener(Function(List<AppNotification>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(List<AppNotification>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(List.unmodifiable(_notifications));
    }
  }

  Future<void> createRemoteNotificationForUser({
    required String userId,
    required AppNotification notification,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notification.id)
        .set({
      ...notification.toMap(),
      'userId': userId,
      'timestamp': Timestamp.fromDate(notification.timestamp),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Show in-app notification (SnackBar or overlay)
  void _showInAppNotification(AppNotification notification) {
    if (_currentContext == null) return;

    // Check if ScaffoldMessenger is available
    try {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(_currentContext!);
      if (scaffoldMessenger == null) {
        return;
      }

      // Show as SnackBar for immediate feedback
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: notification.typeColor,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              handleNotificationTap(notification, callerContext: _currentContext);
            },
          ),
        ),
      );
    } catch (e) {
      // Silently fail - notifications shouldn't crash the app
    }
  }

  // Actual push is delivered by Cloud Functions writing to FCM.
  // This stub is kept so call-sites don't break; FCM sends the real push.
  void _simulatePushNotification(AppNotification notification) {}

  // Handle notification tap actions
  // [callerContext] — pass the widget's own BuildContext when available (preferred).
  // Falls back to the stored _currentContext if omitted.
  Future<void> handleNotificationTap(AppNotification notification,
      {BuildContext? callerContext}) async {
    final ctx = callerContext ?? _currentContext;
    if (ctx == null) return;

    // Mark as read when tapped
    markAsRead(notification.id);

    // Capture navigator BEFORE any await — context may become invalid after async gap
    if (!ctx.mounted) return;
    final navigator = Navigator.of(ctx);

    switch (notification.actionData) {
      case 'surplus_list':
        final ngoName = await _resolveCurrentNgoName();
        if (!navigator.mounted) return;
        navigator.push(
          MaterialPageRoute(
              builder: (_) => SurplusListScreen(ngoName: ngoName)),
        );
        break;
      case 'donor_dashboard':
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        break;
      case 'ngo_dashboard':
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        break;
      case 'my_requests':
        navigator.push(
          MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
        );
        break;
      case 'request_list':
        navigator.push(
          MaterialPageRoute(builder: (_) => const RequestListScreen()),
        );
        break;
      default:
        final roomId = _extractChatRoomId(notification);
        if (roomId != null) {
          final otherUserName =
              await _resolveChatUserName(notification, roomId);
          if (!navigator.mounted) return;
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatRoomId: roomId,
                otherUserName: otherUserName,
              ),
            ),
          );
          break;
        }
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        break;
    }
  }

  String? _extractChatRoomId(AppNotification notification) {
    if (notification.relatedChatRoomId != null &&
        notification.relatedChatRoomId!.isNotEmpty) {
      return notification.relatedChatRoomId;
    }

    final action = notification.actionData;
    if (action != null && action.startsWith('chat_') && action.length > 5) {
      return action.substring(5);
    }
    return null;
  }

  Future<String> _resolveChatUserName(
    AppNotification notification,
    String roomId,
  ) async {
    if (notification.relatedUserName != null &&
        notification.relatedUserName!.trim().isNotEmpty) {
      return notification.relatedUserName!.trim();
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final roomSnap = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .get();
      final participants =
          List<String>.from(roomSnap.data()?['participantIds'] ?? const []);
      final otherUserId = participants.firstWhere(
        (participantId) => participantId != uid,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) return 'FoodBridge';

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      final data = userSnap.data();
      return (data?['userName'] ?? data?['organizationName'] ?? data?['email'])
              ?.toString() ??
          'FoodBridge';
    } catch (_) {
      return 'FoodBridge';
    }
  }

  Future<String> _resolveCurrentNgoName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'NGO';
      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userSnap.data();
      return (data?['organizationName'] ?? data?['userName'] ?? data?['email'])
              ?.toString() ??
          'NGO';
    } catch (_) {
      return 'NGO';
    }
  }

  // Get statistics
  Map<String, int> getStatistics() {
    return {
      'total': _notifications.length,
      'unread': unreadCount,
      'surplusReported':
          getNotificationsByType(NotificationType.surplusReported).length,
      'surplusAccepted':
          getNotificationsByType(NotificationType.surplusAccepted).length,
      'surplusCollected':
          getNotificationsByType(NotificationType.surplusCollected).length,
      'claimReceived':
          getNotificationsByType(NotificationType.claimReceived).length,
      'claimAccepted':
          getNotificationsByType(NotificationType.claimAccepted).length,
      'claimRejected':
          getNotificationsByType(NotificationType.claimRejected).length,
      'pickupReminder':
          getNotificationsByType(NotificationType.pickupReminder).length,
      'expiryReminder':
          getNotificationsByType(NotificationType.expiryReminder).length,
      'requestFulfilled':
          getNotificationsByType(NotificationType.requestFulfilled).length,
      'requestCreated':
          getNotificationsByType(NotificationType.requestCreated).length,
      'newMessage': getNotificationsByType(NotificationType.newMessage).length,
      'general': getNotificationsByType(NotificationType.general).length,
    };
  }

  // Helper methods
  String _generateId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
