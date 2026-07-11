import 'package:flutter/material.dart';

enum NotificationType {
  surplusReported, // New food available
  surplusAccepted, // NGO accepted donation
  surplusCollected, // Donation collected
  claimReceived, // Claim request received (for donors)
  claimAccepted, // Claim approved (for NGOs)
  claimRejected, // Claim denied
  pickupReminder, // Pickup deadline approaching
  expiryReminder, // Food expiring soon
  requestFulfilled, // Request was fulfilled
  requestCreated, // New request created (for donors to see)
  newMessage, // New chat message
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
  final String? relatedDonationId;
  final String? relatedRequestId;
  final String? relatedChatRoomId;
  final String? relatedUserName;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.priority = NotificationPriority.medium,
    this.actionData,
    this.imageUrl,
    this.isRead = false,
    this.relatedDonationId,
    this.relatedRequestId,
    this.relatedChatRoomId,
    this.relatedUserName,
  });

  // Convert to map for future database integration
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp.toIso8601String(),
      'actionData': actionData,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'relatedDonationId': relatedDonationId,
      'relatedRequestId': relatedRequestId,
      'relatedChatRoomId': relatedChatRoomId,
      'relatedUserName': relatedUserName,
    };
  }

  // Create from map for future database integration
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final parsedTimestamp = rawTimestamp is DateTime
        ? rawTimestamp
        : rawTimestamp is String
            ? DateTime.tryParse(rawTimestamp) ?? DateTime.now()
            : rawTimestamp != null &&
                    rawTimestamp.runtimeType.toString() == 'Timestamp'
                ? (rawTimestamp as dynamic).toDate() as DateTime
                : DateTime.now();

    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'] || e.toString() == map['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'] || e.toString() == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: parsedTimestamp,
      actionData: map['actionData'],
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      relatedDonationId: map['relatedDonationId'],
      relatedRequestId: map['relatedRequestId'],
      relatedChatRoomId: map['relatedChatRoomId'],
      relatedUserName: map['relatedUserName'],
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
    String? relatedDonationId,
    String? relatedRequestId,
    String? relatedChatRoomId,
    String? relatedUserName,
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
      relatedDonationId: relatedDonationId ?? this.relatedDonationId,
      relatedRequestId: relatedRequestId ?? this.relatedRequestId,
      relatedChatRoomId: relatedChatRoomId ?? this.relatedChatRoomId,
      relatedUserName: relatedUserName ?? this.relatedUserName,
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
        return 'New Surplus';
      case NotificationType.surplusAccepted:
        return 'Surplus Accepted';
      case NotificationType.surplusCollected:
        return 'Surplus Collected';
      case NotificationType.claimReceived:
        return 'New Claim';
      case NotificationType.claimAccepted:
        return 'Claim Approved';
      case NotificationType.claimRejected:
        return 'Claim Rejected';
      case NotificationType.pickupReminder:
        return 'Pickup Reminder';
      case NotificationType.expiryReminder:
        return 'Expiry Warning';
      case NotificationType.requestFulfilled:
        return 'Request Fulfilled';
      case NotificationType.requestCreated:
        return 'New Request';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.general:
        return 'General';
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.surplusReported:
        return Colors.green;
      case NotificationType.surplusAccepted:
        return Colors.blue;
      case NotificationType.surplusCollected:
        return Colors.purple;
      case NotificationType.claimReceived:
        return Colors.orange;
      case NotificationType.claimAccepted:
        return Colors.green;
      case NotificationType.claimRejected:
        return Colors.red;
      case NotificationType.pickupReminder:
        return Colors.amber;
      case NotificationType.expiryReminder:
        return Colors.red;
      case NotificationType.requestFulfilled:
        return Colors.teal;
      case NotificationType.requestCreated:
        return Colors.indigo;
      case NotificationType.newMessage:
        return Colors.blue;
      case NotificationType.general:
        return Colors.grey;
    }
  }
}
