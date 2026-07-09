import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/request/my_requests_screen.dart';
import '../screens/request/request_list_screen.dart';
import '../models/notification_model.dart';

class NotificationService {
  // Singleton pattern for global access
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // In-memory storage (will be replaced with Firebase later)
  final List<AppNotification> _notifications = [];
  
  // Listeners for real-time updates
  final List<Function(List<AppNotification>)> _listeners = [];
  
  // Current context for showing snackbars (set by main app)
  BuildContext? _currentContext;

  // ── FCM ────────────────────────────────────────────────────────────────────

  /// Call once after Firebase is ready and the user is signed in.
  /// Registers/refreshes the FCM token and sets up foreground + tap handlers.
  Future<void> initializeFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS / web)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token, 'notificationsEnabled': true},
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

  void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = AppNotification(
      id: data['notificationId'] ?? _generateId(),
      title: message.notification?.title ?? data['title'] ?? 'FoodBridge',
      message: message.notification?.body ?? data['body'] ?? '',
      type: _parseType(data['type']),
      priority: _parsePriority(data['priority']),
      timestamp: DateTime.now(),
      actionData: data['actionData'],
      relatedDonationId: data['donationId'],
      relatedRequestId: data['requestId'],
    );
    // Insert into in-memory list and show SnackBar (existing system unchanged)
    _notifications.insert(0, notification);
    _notifyListeners();
    _showInAppNotification(notification);
  }

  void _onNotificationTap(RemoteMessage message) {
    final data = message.data;
    final notification = AppNotification(
      id: data['notificationId'] ?? _generateId(),
      title: message.notification?.title ?? '',
      message: message.notification?.body ?? '',
      type: _parseType(data['type']),
      timestamp: DateTime.now(),
      actionData: data['actionData'],
      relatedDonationId: data['donationId'],
      relatedRequestId: data['requestId'],
    );
    // Mark read immediately and navigate
    _notifications.insert(0, notification);
    _notifyListeners();
    _handleNotificationTap(notification);
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

  // Initialize with some mock notifications
  void initializeMockData() {
    if (_notifications.isEmpty) {
      _notifications.addAll([
        AppNotification(
          id: _generateId(),
          title: 'Welcome to FoodBridge!',
          message: 'Start reducing food waste by connecting with your community.',
          type: NotificationType.general,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AppNotification(
          id: _generateId(),
          title: 'New Surplus Available',
          message: 'Fresh vegetables available for pickup from Green Grocery Store.',
          type: NotificationType.surplusReported,
          priority: NotificationPriority.high,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ]);
      _notifyListeners();
    }
  }

  // Set current context for showing UI notifications
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  // Get all notifications
  List<AppNotification> getAllNotifications() {
    return List.unmodifiable(_notifications);
  }

  // Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  // Add new notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification); // Add to beginning for chronological order
    _notifyListeners();
    
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
      message: '$donorName has reported $quantity units of $foodType. Check it out!',
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
      message: '$ngoName has accepted your $foodType donation. They will coordinate pickup soon.',
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
      message: 'Your $foodType donation has been successfully collected by $ngoName. Thank you for reducing food waste!',
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
      message: '$ngoName wants to claim your $foodType donation. Review and accept the request.',
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
      message: '$donorName has approved your claim for $foodType. Coordinate pickup details.',
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
      message: 'Your claim for $foodType was not approved. Reason: $rejectionReason',
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
      message: 'Pick up $foodType from $donorName within $hoursLeft hours to prevent waste!',
      type: NotificationType.pickupReminder,
      priority: hoursLeft < 6 ? NotificationPriority.urgent : NotificationPriority.high,
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
      message: '$foodType will expire in $hoursLeft hours. Coordinate immediate pickup.',
      type: NotificationType.expiryReminder,
      priority: hoursLeft < 12 ? NotificationPriority.urgent : NotificationPriority.high,
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
      message: '$fulfilledByDonor has provided the $requestTitle you requested.',
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
  }

  // Public method to show in-app notifications
  void showInAppNotification(String title, String message, {NotificationType? type}) {
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
    _notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
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
              _handleNotificationTap(notification);
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
  void _handleNotificationTap(AppNotification notification) {
    if (_currentContext == null) return;

    // Mark as read when tapped
    markAsRead(notification.id);

    // Navigate based on action data
    final navigator = Navigator.of(_currentContext!);
    switch (notification.actionData) {
      case 'surplus_list':
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
        if (notification.actionData?.startsWith('chat_') ?? false) {
          final roomId = notification.actionData!.substring(5);
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatRoomId: roomId,
                otherUserName: 'FoodBridge',
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

  // Get statistics
  Map<String, int> getStatistics() {
    return {
      'total': _notifications.length,
      'unread': unreadCount,
      'surplusReported': getNotificationsByType(NotificationType.surplusReported).length,
      'surplusAccepted': getNotificationsByType(NotificationType.surplusAccepted).length,
      'surplusCollected': getNotificationsByType(NotificationType.surplusCollected).length,
      'claimReceived': getNotificationsByType(NotificationType.claimReceived).length,
      'claimAccepted': getNotificationsByType(NotificationType.claimAccepted).length,
      'claimRejected': getNotificationsByType(NotificationType.claimRejected).length,
      'pickupReminder': getNotificationsByType(NotificationType.pickupReminder).length,
      'expiryReminder': getNotificationsByType(NotificationType.expiryReminder).length,
      'requestFulfilled': getNotificationsByType(NotificationType.requestFulfilled).length,
      'requestCreated': getNotificationsByType(NotificationType.requestCreated).length,
      'general': getNotificationsByType(NotificationType.general).length,
    };
  }

  // Helper methods
  String _generateId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
