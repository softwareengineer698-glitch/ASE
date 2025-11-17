
enum NotificationType {
  surplusReported,
  surplusAccepted,
  surplusCollected,
  general,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? actionData; // For navigation or actions
  final String? imageUrl;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    required this.timestamp,
    this.actionData,
    this.imageUrl,
    this.isRead = false,
  });

  // Convert to map for future database integration
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'priority': priority.toString(),
      'timestamp': timestamp.toIso8601String(),
      'actionData': actionData,
      'imageUrl': imageUrl,
      'isRead': isRead,
    };
  }

  // Create from map for future database integration
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      actionData: map['actionData'],
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
    );
  }

  // Copy with method for updates
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    String? actionData,
    String? imageUrl,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      actionData: actionData ?? this.actionData,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
    );
  }

  // Helper methods
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.surplusReported:
        return 'Surplus Reported';
      case NotificationType.surplusAccepted:
        return 'Surplus Accepted';
      case NotificationType.surplusCollected:
        return 'Surplus Collected';
      case NotificationType.general:
        return 'General';
    }
  }
}
