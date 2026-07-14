import 'dart:math';
import 'package:flutter/material.dart';
import '../models/push_notification_model.dart';

/// Enhanced notification service with push notification support
/// Provides comprehensive notification management and Firebase integration
class EnhancedNotificationService extends ChangeNotifier {
  // Singleton pattern
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  // Storage
  final List<PushNotificationModel> _pushNotifications = [];
  NotificationPreferences _preferences = NotificationPreferences.defaultPreferences();
  String? _fcmToken;

  // Getters
  List<PushNotificationModel> get allNotifications => List.unmodifiable(_pushNotifications);
  List<PushNotificationModel> get unreadNotifications => 
    _pushNotifications.where((n) => !n.isRead).toList();
  NotificationPreferences get preferences => _preferences;
  String? get fcmToken => _fcmToken;
  int get unreadCount => unreadNotifications.length;

  /// Initialize the service
  Future<void> initialize() async {
    await _loadPreferences();
    await _initializeFCM();
    _generateMockNotifications();
  }

  /// Initialize Firebase Cloud Messaging (simulated)
  Future<void> _initializeFCM() async {
    // Simulate FCM token generation
    _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    print('FCM Token: $_fcmToken');
  }

  /// Load notification preferences
  Future<void> _loadPreferences() async {
    // In real app, load from SharedPreferences
    _preferences = NotificationPreferences.defaultPreferences();
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
    // In real app, save to SharedPreferences
    notifyListeners();
  }

  /// Generate mock notifications for demo
  void _generateMockNotifications() {
    final now = DateTime.now();
    
    _pushNotifications.addAll([
      PushNotificationModel(
        id: _generateId(),
        title: 'Welcome to CareCircle! 🎉',
        body: 'Start reducing food waste by connecting with your community.',
        data: {'screen': 'home'},
        receivedAt: now.subtract(const Duration(hours: 2)),
        channel: NotificationChannel.general,
        priority: NotificationPriority.normal,
      ),
      PushNotificationModel(
        id: _generateId(),
        title: 'New Surplus Available 🥬',
        body: 'Fresh vegetables available for pickup from Green Grocery Store.',
        data: {'screen': 'surplus_list', 'surplus_id': '123'},
        receivedAt: now.subtract(const Duration(minutes: 30)),
        channel: NotificationChannel.surplus,
        priority: NotificationPriority.high,
      ),
      PushNotificationModel(
        id: _generateId(),
        title: 'Pickup Confirmed ✅',
        body: 'Your pickup request has been approved. Pickup scheduled for tomorrow 2 PM.',
        data: {'screen': 'pickup_details', 'pickup_id': '456'},
        receivedAt: now.subtract(const Duration(minutes: 15)),
        channel: NotificationChannel.pickup,
        priority: NotificationPriority.high,
      ),
      PushNotificationModel(
        id: _generateId(),
        title: 'Achievement Unlocked! 🏆',
        body: 'Congratulations! You\'ve earned the "Food Hero" badge for 10 donations.',
        data: {'screen': 'achievements'},
        receivedAt: now.subtract(const Duration(hours: 1)),
        channel: NotificationChannel.social,
        priority: NotificationPriority.low,
      ),
    ]);
    
    notifyListeners();
  }

  /// Send notification using template
  Future<void> sendTemplatedNotification({
    required String templateId,
    required Map<String, String> variables,
    required String userId,
    Map<String, dynamic>? additionalData,
  }) async {
    final template = NotificationTemplate.templates[templateId];
    if (template == null) {
      throw ArgumentError('Template $templateId not found');
    }

    final notification = template.createNotification(
      variables: variables,
      additionalData: additionalData,
    );

    await addNotification(notification);
  }

  /// Add new notification
  Future<void> addNotification(PushNotificationModel notification) async {
    // Check if channel is enabled
    if (!_preferences.isChannelEnabled(notification.channel)) {
      print('Notification blocked: Channel ${notification.channel.displayName} is disabled');
      return;
    }

    // Check quiet hours
    if (_preferences.isInQuietHours() && notification.priority != NotificationPriority.urgent) {
      print('Notification delayed: Quiet hours active');
      // In real app, schedule for later
      return;
    }

    _pushNotifications.insert(0, notification);
    notifyListeners();

    // Simulate platform notification
    _showPlatformNotification(notification);
  }

  /// Simulate platform notification
  void _showPlatformNotification(PushNotificationModel notification) {
    print('📱 Platform Notification:');
    print('Title: ${notification.title}');
    print('Body: ${notification.body}');
    print('Channel: ${notification.channel.displayName}');
    print('Priority: ${notification.priority.displayName}');
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _pushNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _pushNotifications[index] = _pushNotifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _pushNotifications.length; i++) {
      if (!_pushNotifications[i].isRead) {
        _pushNotifications[i] = _pushNotifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  /// Delete notification
  void deleteNotification(String notificationId) {
    _pushNotifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _pushNotifications.clear();
    notifyListeners();
  }

  /// Get notifications by channel
  List<PushNotificationModel> getNotificationsByChannel(NotificationChannel channel) {
    return _pushNotifications.where((n) => n.channel == channel).toList();
  }

  /// Get notifications by priority
  List<PushNotificationModel> getNotificationsByPriority(NotificationPriority priority) {
    return _pushNotifications.where((n) => n.priority == priority).toList();
  }

  /// Update channel preference
  void updateChannelPreference(NotificationChannel channel, bool enabled) {
    final newPreferences = Map<NotificationChannel, bool>.from(_preferences.channelPreferences);
    newPreferences[channel] = enabled;
    
    _preferences = _preferences.copyWith(channelPreferences: newPreferences);
    savePreferences(_preferences);
  }

  /// Update sound preference
  void updateSoundPreference(bool enabled) {
    _preferences = _preferences.copyWith(soundEnabled: enabled);
    savePreferences(_preferences);
  }

  /// Update vibration preference
  void updateVibrationPreference(bool enabled) {
    _preferences = _preferences.copyWith(vibrationEnabled: enabled);
    savePreferences(_preferences);
  }

  /// Update quiet hours
  void updateQuietHours({
    required String startTime,
    required String endTime,
    required bool enabled,
  }) {
    _preferences = _preferences.copyWith(
      quietHoursStart: startTime,
      quietHoursEnd: endTime,
      quietHoursEnabled: enabled,
    );
    savePreferences(_preferences);
  }

  /// Send surplus reported notification
  Future<void> notifySurplusReported({
    required String donorName,
    required String category,
    required String quantity,
    required String surplusId,
  }) async {
    await sendTemplatedNotification(
      templateId: 'surplus_reported',
      variables: {
        'donorName': donorName,
        'category': category,
        'quantity': quantity,
      },
      userId: 'current_user',
      additionalData: {
        'screen': 'surplus_list',
        'surplus_id': surplusId,
      },
    );
  }

  /// Send pickup request notification
  Future<void> notifyPickupRequested({
    required String ngoName,
    required String category,
    required String requestId,
  }) async {
    await sendTemplatedNotification(
      templateId: 'pickup_requested',
      variables: {
        'ngoName': ngoName,
        'category': category,
      },
      userId: 'current_user',
      additionalData: {
        'screen': 'pickup_requests',
        'request_id': requestId,
      },
    );
  }

  /// Send pickup confirmed notification
  Future<void> notifyPickupConfirmed({
    required String pickupTime,
    required String pickupId,
  }) async {
    await sendTemplatedNotification(
      templateId: 'pickup_confirmed',
      variables: {
        'pickupTime': pickupTime,
      },
      userId: 'current_user',
      additionalData: {
        'screen': 'pickup_details',
        'pickup_id': pickupId,
      },
    );
  }

  /// Send delivery completed notification
  Future<void> notifyDeliveryCompleted({
    required String quantity,
    required String ngoName,
    required String deliveryId,
  }) async {
    await sendTemplatedNotification(
      templateId: 'delivery_completed',
      variables: {
        'quantity': quantity,
        'ngoName': ngoName,
      },
      userId: 'current_user',
      additionalData: {
        'screen': 'delivery_details',
        'delivery_id': deliveryId,
      },
    );
  }

  /// Send achievement notification
  Future<void> notifyAchievementUnlocked({
    required String achievementName,
    required String achievementId,
  }) async {
    await sendTemplatedNotification(
      templateId: 'achievement_unlocked',
      variables: {
        'achievementName': achievementName,
      },
      userId: 'current_user',
      additionalData: {
        'screen': 'achievements',
        'achievement_id': achievementId,
      },
    );
  }

  /// Send forecast alert notification
  Future<void> notifyForecastAlert({
    required String riskLevel,
    required String forecastId,
  }) async {
    await sendTemplatedNotification(
      templateId: 'forecast_alert',
      variables: {
        'riskLevel': riskLevel,
      },
      userId: 'current_user',
      additionalData: {
        'screen': 'forecast_dashboard',
        'forecast_id': forecastId,
      },
    );
  }

  /// Request notification permissions (simulated)
  Future<bool> requestPermissions() async {
    // Simulate permission request
    await Future.delayed(const Duration(milliseconds: 500));
    print('📱 Notification permissions requested');
    return true; // Assume granted
  }

  /// Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    print('📡 Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    print('📡 Unsubscribed from topic: $topic');
  }

  /// Handle notification tap
  void handleNotificationTap(PushNotificationModel notification) {
    // Mark as read
    markAsRead(notification.id);
    
    // Handle navigation based on data
    final screen = notification.data['screen'];
    print('🔗 Navigate to: $screen');
    print('📊 Notification data: ${notification.data}');
  }

  /// Get notification statistics
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{};
    
    for (final channel in NotificationChannel.values) {
      stats[channel.displayName] = getNotificationsByChannel(channel).length;
    }
    
    stats['Total'] = _pushNotifications.length;
    stats['Unread'] = unreadCount;
    
    return stats;
  }

  /// Generate unique ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Test notification (for demo purposes)
  Future<void> sendTestNotification() async {
    final testNotification = PushNotificationModel(
      id: _generateId(),
      title: 'Test Notification 🧪',
      body: 'This is a test notification to verify the system is working.',
      data: {'screen': 'test'},
      receivedAt: DateTime.now(),
      channel: NotificationChannel.system,
      priority: NotificationPriority.normal,
    );
    
    await addNotification(testNotification);
  }
}
