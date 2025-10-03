import 'dart:math';
import 'package:flutter/material.dart';
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

  // Initialize with some mock notifications
  void initializeMockData() {
    if (_notifications.isEmpty) {
      _notifications.addAll([
        AppNotification(
          id: _generateId(),
          title: 'Welcome to FoodBridge!',
          message: 'Start reducing food waste by connecting with your community.',
          type: NotificationType.general,
          priority: NotificationPriority.medium,
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

  // Create and send surplus reported notification
  Future<void> notifySurplusReported({
    required String donorName,
    required String foodType,
    required int quantity,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'New Surplus Available! 🍎',
      message: '$donorName has reported $quantity units of $foodType. Check it out!',
      type: NotificationType.surplusReported,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'surplus_list', // For navigation
    );
    
    await addNotification(notification);
  }

  // Create and send surplus accepted notification
  Future<void> notifySurplusAccepted({
    required String ngoName,
    required String foodType,
    required String donorName,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Surplus Accepted! ✅',
      message: '$ngoName has accepted your $foodType donation. They will coordinate pickup soon.',
      type: NotificationType.surplusAccepted,
      priority: NotificationPriority.high,
      timestamp: DateTime.now(),
      actionData: 'donor_dashboard', // For navigation
    );
    
    await addNotification(notification);
  }

  // Create and send surplus collected notification
  Future<void> notifySurplusCollected({
    required String foodType,
    required String ngoName,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: 'Surplus Collected! 🎉',
      message: 'Your $foodType donation has been successfully collected by $ngoName. Thank you for reducing food waste!',
      type: NotificationType.surplusCollected,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
    );
    
    await addNotification(notification);
  }

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
      priority: NotificationPriority.medium,
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
        print('ScaffoldMessenger not available, skipping in-app notification');
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
        backgroundColor: _getNotificationColor(notification.type),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Handle notification tap (navigate to relevant screen)
            _handleNotificationTap(notification);
          },
        ),
      ));
    } catch (e) {
      print('Error showing in-app notification: $e');
    }
  }

  // Simulate push notification (placeholder for Firebase)
  void _simulatePushNotification(AppNotification notification) {
    // In a real app, this would send to Firebase Cloud Messaging
    print('🔔 PUSH NOTIFICATION: ${notification.title}');
    print('   Message: ${notification.message}');
    print('   Type: ${notification.type}');
    print('   Priority: ${notification.priority}');
  }

  // Handle notification tap actions
  void _handleNotificationTap(AppNotification notification) {
    if (_currentContext == null) return;

    // Mark as read when tapped
    markAsRead(notification.id);

    // Navigate based on action data
    switch (notification.actionData) {
      case 'surplus_list':
        // Navigate to surplus list (for NGOs)
        break;
      case 'donor_dashboard':
        // Navigate to donor dashboard
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  // Get color based on notification type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.surplusReported:
        return Colors.green;
      case NotificationType.surplusAccepted:
        return Colors.blue;
      case NotificationType.surplusCollected:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  // Helper methods
  String _generateId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Get statistics
  Map<String, int> getStatistics() {
    return {
      'total': _notifications.length,
      'unread': unreadCount,
      'surplusReported': getNotificationsByType(NotificationType.surplusReported).length,
      'surplusAccepted': getNotificationsByType(NotificationType.surplusAccepted).length,
      'surplusCollected': getNotificationsByType(NotificationType.surplusCollected).length,
      'general': getNotificationsByType(NotificationType.general).length,
    };
  }
}
