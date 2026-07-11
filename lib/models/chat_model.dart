import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final String type; // 'donor_ngo', 'ngo_volunteer', 'donor_volunteer'
  final Map<String, int> unreadCounts; // userId -> count

  ChatRoomModel({
    required this.id,
    required this.participantIds,
    required this.lastMessageAt, required this.type, this.lastMessage,
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'type': type,
      'unreadCounts': unreadCounts,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatRoomModel(
      id: documentId,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp).toDate(),
      type: map['type'] ?? '',
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawSentAt = map['sentAt'];
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      sentAt: rawSentAt is Timestamp ? rawSentAt.toDate() : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
