import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely converts any Firestore timestamp-like value to DateTime.
/// Handles: Timestamp, int (milliseconds), null — never crashes.
DateTime _toDateTime(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  return DateTime.fromMillisecondsSinceEpoch(0);
}

class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final String type;
  final Map<String, int> unreadCounts;

  ChatRoomModel({
    required this.id,
    required this.participantIds,
    required this.lastMessageAt,
    required this.type,
    this.lastMessage,
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() => {
        'participantIds': participantIds,
        'lastMessage': lastMessage,
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        'type': type,
        'unreadCounts': unreadCounts,
      };

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String documentId) =>
      ChatRoomModel(
        id: documentId,
        participantIds: List<String>.from(map['participantIds'] ?? []),
        lastMessage: map['lastMessage'] as String?,
        lastMessageAt: _toDateTime(map['lastMessageAt']),
        type: map['type'] as String? ?? '',
        unreadCounts: (map['unreadCounts'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
            {},
      );
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  /// Always stores sentAt as Timestamp for consistent Firestore ordering.
  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'isRead': isRead,
      };

  /// Handles both Timestamp and int sentAt — never crashes.
  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) =>
      MessageModel(
        id: documentId,
        senderId: map['senderId'] as String? ?? '',
        text: map['text'] as String? ?? '',
        sentAt: _toDateTime(map['sentAt']),
        isRead: map['isRead'] as bool? ?? false,
      );
}
