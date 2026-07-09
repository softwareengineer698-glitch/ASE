/// Models for Firebase push notifications
/// Handles different notification types and user preferences
library;

class PushNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final NotificationChannel channel;
  final NotificationPriority priority;
  final bool isRead;

  const PushNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data, required this.receivedAt, required this.channel, required this.priority, this.imageUrl,
    this.isRead = false,
  });

  factory PushNotificationModel.fromMap(Map<String, dynamic> map) {
    return PushNotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      receivedAt: DateTime.parse(map['receivedAt'] ?? DateTime.now().toIso8601String()),
      channel: NotificationChannel.values.firstWhere(
        (e) => e.name == map['channel'],
        orElse: () => NotificationChannel.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
      'channel': channel.name,
      'priority': priority.name,
      'isRead': isRead,
    };
  }

  PushNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
    NotificationChannel? channel,
    NotificationPriority? priority,
    bool? isRead,
  }) {
    return PushNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      receivedAt: receivedAt ?? this.receivedAt,
      channel: channel ?? this.channel,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(receivedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${receivedAt.day}/${receivedAt.month}/${receivedAt.year}';
    }
  }
}

/// Notification channels for categorization
enum NotificationChannel {
  general,
  surplus,
  pickup,
  delivery,
  alerts,
  social,
  system;

  String get displayName {
    switch (this) {
      case NotificationChannel.general:
        return 'General';
      case NotificationChannel.surplus:
        return 'Surplus Updates';
      case NotificationChannel.pickup:
        return 'Pickup Requests';
      case NotificationChannel.delivery:
        return 'Delivery Updates';
      case NotificationChannel.alerts:
        return 'Important Alerts';
      case NotificationChannel.social:
        return 'Social & Achievements';
      case NotificationChannel.system:
        return 'System Updates';
    }
  }

  String get description {
    switch (this) {
      case NotificationChannel.general:
        return 'General app notifications';
      case NotificationChannel.surplus:
        return 'New surplus reports and updates';
      case NotificationChannel.pickup:
        return 'Pickup scheduling and confirmations';
      case NotificationChannel.delivery:
        return 'Delivery status and confirmations';
      case NotificationChannel.alerts:
        return 'Critical alerts and warnings';
      case NotificationChannel.social:
        return 'Achievements, leaderboards, and social updates';
      case NotificationChannel.system:
        return 'App updates and maintenance notices';
    }
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}

/// User notification preferences
class NotificationPreferences {
  final bool pushNotificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool badgeEnabled;
  final Map<NotificationChannel, bool> channelPreferences;
  final String quietHoursStart; // HH:mm format
  final String quietHoursEnd; // HH:mm format
  final bool quietHoursEnabled;

  const NotificationPreferences({
    required this.channelPreferences, this.pushNotificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.badgeEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.quietHoursEnabled = false,
  });

  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      channelPreferences: {
        for (var channel in NotificationChannel.values) channel: true,
      },
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      badgeEnabled: map['badgeEnabled'] ?? true,
      channelPreferences: Map<NotificationChannel, bool>.fromEntries(
        NotificationChannel.values.map((channel) => MapEntry(
          channel,
          map['channelPreferences']?[channel.name] ?? true,
        )),
      ),
      quietHoursStart: map['quietHoursStart'] ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] ?? '08:00',
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'badgeEnabled': badgeEnabled,
      'channelPreferences': {
        for (var entry in channelPreferences.entries) entry.key.name: entry.value,
      },
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursEnabled': quietHoursEnabled,
    };
  }

  NotificationPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeEnabled,
    Map<NotificationChannel, bool>? channelPreferences,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationPreferences(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      channelPreferences: channelPreferences ?? this.channelPreferences,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }

  bool isChannelEnabled(NotificationChannel channel) {
    return pushNotificationsEnabled && (channelPreferences[channel] ?? true);
  }

  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Simple time comparison (doesn't handle cross-midnight scenarios perfectly)
    return currentTime.compareTo(quietHoursStart) >= 0 || 
           currentTime.compareTo(quietHoursEnd) <= 0;
  }
}

/// Notification action for interactive notifications
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool requiresAuthentication;
  final Map<String, dynamic>? data;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.requiresAuthentication = false,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'requiresAuthentication': requiresAuthentication,
      'data': data,
    };
  }
}

/// Notification template for consistent messaging
class NotificationTemplate {
  final String id;
  final String titleTemplate;
  final String bodyTemplate;
  final NotificationChannel channel;
  final NotificationPriority priority;
  final List<NotificationAction> actions;

  const NotificationTemplate({
    required this.id,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.channel,
    required this.priority,
    this.actions = const [],
  });

  PushNotificationModel createNotification({
    required Map<String, String> variables,
    Map<String, dynamic>? additionalData,
  }) {
    String title = titleTemplate;
    String body = bodyTemplate;

    // Replace variables in templates
    variables.forEach((key, value) {
      title = title.replaceAll('{{$key}}', value);
      body = body.replaceAll('{{$key}}', value);
    });

    return PushNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      data: additionalData ?? {},
      receivedAt: DateTime.now(),
      channel: channel,
      priority: priority,
    );
  }

  static const Map<String, NotificationTemplate> templates = {
    'surplus_reported': NotificationTemplate(
      id: 'surplus_reported',
      titleTemplate: 'New Surplus Available',
      bodyTemplate: '{{donorName}} has reported {{quantity}}kg of {{category}} surplus',
      channel: NotificationChannel.surplus,
      priority: NotificationPriority.normal,
      actions: [
        NotificationAction(
          id: 'view_surplus',
          title: 'View Details',
        ),
        NotificationAction(
          id: 'request_pickup',
          title: 'Request Pickup',
        ),
      ],
    ),
    'pickup_requested': NotificationTemplate(
      id: 'pickup_requested',
      titleTemplate: 'Pickup Request Received',
      bodyTemplate: '{{ngoName}} has requested to pickup your {{category}} surplus',
      channel: NotificationChannel.pickup,
      priority: NotificationPriority.high,
      actions: [
        NotificationAction(
          id: 'approve_pickup',
          title: 'Approve',
        ),
        NotificationAction(
          id: 'view_request',
          title: 'View Details',
        ),
      ],
    ),
    'pickup_confirmed': NotificationTemplate(
      id: 'pickup_confirmed',
      titleTemplate: 'Pickup Confirmed',
      bodyTemplate: 'Your pickup request has been approved. Pickup scheduled for {{pickupTime}}',
      channel: NotificationChannel.pickup,
      priority: NotificationPriority.high,
    ),
    'delivery_completed': NotificationTemplate(
      id: 'delivery_completed',
      titleTemplate: 'Delivery Completed',
      bodyTemplate: 'Your donation of {{quantity}}kg has been successfully delivered to {{ngoName}}',
      channel: NotificationChannel.delivery,
      priority: NotificationPriority.normal,
    ),
    'achievement_unlocked': NotificationTemplate(
      id: 'achievement_unlocked',
      titleTemplate: 'Achievement Unlocked! 🏆',
      bodyTemplate: 'Congratulations! You\'ve earned the "{{achievementName}}" badge',
      channel: NotificationChannel.social,
      priority: NotificationPriority.low,
    ),
    'forecast_alert': NotificationTemplate(
      id: 'forecast_alert',
      titleTemplate: 'Surplus Alert',
      bodyTemplate: 'AI predicts {{riskLevel}} surplus risk for tomorrow. Consider planning donations.',
      channel: NotificationChannel.alerts,
      priority: NotificationPriority.high,
    ),
  };
}
