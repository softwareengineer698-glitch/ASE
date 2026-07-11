import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;

  const ChatScreen({
    required this.chatRoomId,
    required this.otherUserName,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = FirebaseFirestore.instance;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _currentUid =>
      Provider.of<AuthProvider>(context, listen: false).user?.uid ??
      fb_auth.FirebaseAuth.instance.currentUser?.uid ??
      '';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send message ────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final uid = _currentUid;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not signed in — cannot send message.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _msgController.clear();

    final roomRef = _db.collection('chat_rooms').doc(widget.chatRoomId);
    final msgRef = roomRef.collection('messages').doc();
    final sentAt = DateTime.now();

    try {
      final roomSnap = await roomRef.get();
      final participants = List<String>.from(
          (roomSnap.data()?['participantIds'] as List?) ?? const []);

      // Write the message
      await msgRef.set(
        MessageModel(
          id: msgRef.id,
          senderId: uid,
          text: text,
          sentAt: sentAt,
        ).toMap(),
      );

      // Update room metadata + unread counts for others
      final Map<String, dynamic> roomUpdate = {
        'lastMessage': text,
        'lastMessageAt': Timestamp.fromDate(sentAt),
      };
      for (final pid in participants) {
        if (pid != uid) {
          roomUpdate['unreadCounts.$pid'] = FieldValue.increment(1);
        }
      }
      await roomRef.set(roomUpdate, SetOptions(merge: true));

      // Write in-app notification for the other participants
      final senderSnap = await _db.collection('users').doc(uid).get();
      final sd = senderSnap.data();
      final senderName =
          (sd?['organizationName'] ?? sd?['userName'] ?? sd?['email'] ?? 'FoodBridge')
              .toString();

      for (final pid in participants) {
        if (pid == uid) continue;
        try {
          await _db
              .collection('notifications')
              .doc('chat_${widget.chatRoomId}_${msgRef.id}_$pid')
              .set({
            'id': 'chat_${widget.chatRoomId}_${msgRef.id}_$pid',
            'userId': pid,
            'title': 'New Message from $senderName',
            'message': text,
            'type': 'newMessage',
            'priority': 'high',
            'timestamp': Timestamp.fromDate(sentAt),
            'actionData': 'chat_${widget.chatRoomId}',
            'relatedChatRoomId': widget.chatRoomId,
            'relatedUserName': senderName,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {
          // Notification failure must not block the chat
        }
      }

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      _msgController.text = text;
      _msgController.selection =
          TextSelection.collapsed(offset: _msgController.text.length);
    }
  }

  // ── Delete single message ────────────────────────────────────────────────────
  Future<void> _deleteMessage(String messageId, String senderId) async {
    final uid = _currentUid;
    if (uid != senderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own messages.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message for everyone?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await _db
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // ── Delete entire chat ───────────────────────────────────────────────────────
  Future<void> _deleteEntireChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
            'This will permanently delete all messages in this chat for both users. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Delete all messages in the sub-collection
      final msgs = await _db
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .get();
      final batch = _db.batch();
      for (final doc in msgs.docs) {
        batch.delete(doc.reference);
      }
      // Reset the room metadata
      batch.update(
        _db.collection('chat_rooms').doc(widget.chatRoomId),
        {
          'lastMessage': null,
          'lastMessageAt': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text('discuss_pickup'.tr(),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete entire chat',
            onPressed: _deleteEntireChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'chat_info_banner'.tr(),
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('sentAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('no_messages_yet'.tr(),
                        style: TextStyle(color: Colors.grey[600])),
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final msg = MessageModel.fromMap(
                        docs[i].data() as Map<String, dynamic>,
                        docs[i].id);
                    final isMe = msg.senderId == uid;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      onLongPress: () =>
                          _deleteMessage(msg.id, msg.senderId),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'type_message'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _sendMessage,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.sentAt.hour}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white70
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
