import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late final String _uid;

  @override
  void initState() {
    super.initState();
    // Capture uid once — safe even if Provider rebuilds later
    _uid = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (_uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Not signed in. Cannot send message.'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    _msgController.clear(); // immediate UX

    try {
      final roomRef = _db.collection('chat_rooms').doc(widget.chatRoomId);
      final now = Timestamp.now(); // always Timestamp — consistent format

      // 1. Write the message
      await roomRef.collection('messages').add({
        'senderId': _uid,
        'text': text,
        'sentAt': now,          // Timestamp — consistent with orderBy
        'isRead': false,
      });

      // 2. Update room (fire-and-forget — don't await, don't block send)
      unawaited(roomRef.set({
        'lastMessage': text,
        'lastMessageAt': now,
        'unreadCounts': {_uid: 0},
      }, SetOptions(merge: true)));

      // 3. Increment unread for other participants (fire-and-forget)
      unawaited(_incrementUnread(roomRef));

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _msgController.text = text; // restore on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Send failed: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _incrementUnread(DocumentReference roomRef) async {
    try {
      final snap = await roomRef.get();
      if (!snap.exists) return;
      final participants = List<String>.from(
          (snap.data() as Map<String, dynamic>?)?['participantIds'] ?? []);
      final Map<String, dynamic> updates = {};
      for (final pid in participants) {
        if (pid != _uid) {
          updates['unreadCounts.$pid'] = FieldValue.increment(1);
        }
      }
      if (updates.isNotEmpty) await roomRef.update(updates);
    } catch (_) {
      // Non-critical — don't surface to user
    }
  }

  Future<void> _deleteMessage(String docId, String senderId) async {
    if (_uid != senderId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You can only delete your own messages.')),
        );
      }
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Remove this message for everyone?'),
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
    if (ok != true || !mounted) return;
    await _db
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .doc(docId)
        .delete();
  }

  Future<void> _deleteEntireChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text(
            'This deletes all messages for everyone. Cannot be undone.'),
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
    if (ok != true || !mounted) return;
    try {
      final msgs = await _db
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .get();
      final batch = _db.batch();
      for (final d in msgs.docs) {
        batch.delete(d.reference);
      }
      batch.update(
          _db.collection('chat_rooms').doc(widget.chatRoomId),
          {'lastMessage': null, 'lastMessageAt': Timestamp.now()});
      await batch.commit();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            tooltip: 'Delete chat',
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
            color: Colors.green.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'chat_info_banner'.tr(),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.green),
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
                  .orderBy('sentAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ClientSortedMessages(
                    chatRoomId: widget.chatRoomId,
                    uid: _uid,
                    scrollController: _scrollController,
                    onLongPress: _deleteMessage,
                    colorScheme: colorScheme,
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('no_messages_yet'.tr(),
                            style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 6),
                        Text('Send the first message!',
                            style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = MessageModel.fromMap(
                        docs[i].data() as Map<String, dynamic>, docs[i].id);
                    return _Bubble(
                      docId: docs[i].id,
                      senderId: msg.senderId,
                      text: msg.text,
                      time:
                          '${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                      isMe: msg.senderId == _uid,
                      onLongPress: _deleteMessage,
                      colorScheme: colorScheme,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
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
                    color: colorScheme.primary,
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
          ),
        ],
      ),
    );
  }
}

// ── Fallback: client-side sort when Firestore index is missing ─────────────────
class _ClientSortedMessages extends StatelessWidget {
  final String chatRoomId;
  final String uid;
  final ScrollController scrollController;
  final Future<void> Function(String, String) onLongPress;
  final ColorScheme colorScheme;

  const _ClientSortedMessages({
    required this.chatRoomId,
    required this.uid,
    required this.scrollController,
    required this.onLongPress,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = List<QueryDocumentSnapshot>.from(
            snap.data?.docs ?? [])
          ..sort((a, b) {
            final ad = a.data() as Map<String, dynamic>;
            final bd = b.data() as Map<String, dynamic>;
            return _toMs(ad['sentAt']).compareTo(_toMs(bd['sentAt']));
          });
        if (docs.isEmpty) {
          return Center(
            child: Text('no_messages_yet'.tr(),
                style: TextStyle(color: Colors.grey[500])),
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final msg = MessageModel.fromMap(
                docs[i].data() as Map<String, dynamic>, docs[i].id);
            return _Bubble(
              docId: docs[i].id,
              senderId: msg.senderId,
              text: msg.text,
              time:
                  '${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
              isMe: msg.senderId == uid,
              onLongPress: onLongPress,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  static int _toMs(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    return 0;
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final String docId;
  final String senderId;
  final String text;
  final String time;
  final bool isMe;
  final Future<void> Function(String, String) onLongPress;
  final ColorScheme colorScheme;

  const _Bubble({
    required this.docId,
    required this.senderId,
    required this.text,
    required this.time,
    required this.isMe,
    required this.onLongPress,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => onLongPress(docId, senderId),
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
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
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

// Dart doesn't have unawaited in dart:async on older SDKs — define locally
void unawaited(Future<void> future) {
  future.catchError((_) {}); // silently suppress errors on fire-and-forget
}
