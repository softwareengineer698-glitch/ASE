import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_widgets.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _loadNotifications() {
    setState(() {
      _isLoading = true;
    });

    // Initialize mock data and load notifications
    _notificationService.initializeMockData();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _notifications = _notificationService.getAllNotifications();
          _isLoading = false;
        });
      }
    });
  }

  void _onNotificationsChanged(List<AppNotification> notifications) {
    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'Surplus':
        return _notifications
            .where((n) =>
                n.type == NotificationType.surplusReported ||
                n.type == NotificationType.surplusAccepted ||
                n.type == NotificationType.surplusCollected)
            .toList();
      case 'General':
        return _notifications
            .where((n) => n.type == NotificationType.general)
            .toList();
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'mark_all_read'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('clear_all'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text('settings'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Unread',
                  'Surplus',
                  'General',
                ].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryBlue,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Statistics Row
          if (_notifications.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      _notifications.length.toString(),
                      Icons.notifications,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Unread',
                      _notificationService.unreadCount.toString(),
                      Icons.mark_email_unread,
                      AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Today',
                      _getTodayCount().toString(),
                      Icons.today,
                      AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? NotificationEmptyState(
                        title: _getEmptyStateTitle(),
                        message: _getEmptyStateMessage(),
                        onRefresh: _loadNotifications,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadNotifications(),
                        child: ListView.builder(
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return NotificationTile(
                              notification: notification,
                              onTap: () => _handleNotificationTap(notification),
                              onDismiss: () =>
                                  _deleteNotification(notification.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _getTodayCount() {
    final today = DateTime.now();
    return _notifications.where((n) {
      return n.timestamp.year == today.year &&
          n.timestamp.month == today.month &&
          n.timestamp.day == today.day;
    }).length;
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'Unread':
        return 'No Unread Notifications';
      case 'Surplus':
        return 'No Surplus Notifications';
      case 'General':
        return 'No General Notifications';
      default:
        return 'No Notifications';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'Unread':
        return 'You\'re all caught up! All notifications have been read.';
      case 'Surplus':
        return 'No surplus-related notifications yet. They\'ll appear here when surplus is reported or accepted.';
      case 'General':
        return 'No general notifications at the moment.';
      default:
        return 'You\'re all caught up! New notifications will appear here.';
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    _notificationService.markAsRead(notification.id);

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.surplusReported:
        // Navigate to surplus list for NGOs
        break;
      case NotificationType.surplusAccepted:
        // Navigate to donor dashboard
        break;
      case NotificationType.surplusCollected:
        // Show success message or navigate to history
        break;
      case NotificationType.general:
        // Show notification details or do nothing
        break;
    }

    // Show notification details in a dialog
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  notification.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(notification.type.toString())
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          AppTheme.getStatusColor(notification.type.toString()),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
          if (notification.actionData != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle action navigation
              },
              child: Text('view'.tr()),
            ),
        ],
      ),
    );
  }

  void _deleteNotification(String notificationId) {
    _notificationService.deleteNotification(notificationId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('notification_deleted'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('all_notifications_read'.tr()),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_all_notifications'.tr()),
        content: Text('confirm_clear_notifications'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notificationService.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('all_notifications_cleared'.tr()),
                  backgroundColor: AppTheme.primaryOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('clear_all'.tr()),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('notification_settings'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text('push_notifications'.tr()),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: Text('vibration'.tr()),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: Text('sound'.tr()),
              trailing: const Switch(value: true, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }
}
