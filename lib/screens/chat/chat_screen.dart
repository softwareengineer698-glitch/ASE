import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/chat_model.dart';
import '../../services/notification_trigger_service.dart';

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
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _msgController = TextEditingController();
  bool _sending = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) return;
    _scrollController.jumpTo(pos.maxScrollExtent);
  }

  Future<void> _sendMessage() async {
    if (_sending) return;

    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final uid = _uid;
    if (uid.isEmpty) {
      _snack('Not signed in', Colors.red);
      return;
    }

    setState(() => _sending = true);
    _msgController.clear();
    _focusNode.requestFocus();

    try {
      final room = _db.collection('chat_rooms').doc(widget.chatRoomId);
      final now = Timestamp.now();

      await room.collection('messages').add({
        'senderId': uid,
        'text': text,
        'sentAt': now,
        'isRead': false,
      });

      await room.set({
        'lastMessage': text,
        'lastMessageAt': now,
        'unreadCounts': {uid: 0},
      }, SetOptions(merge: true));

      // fire-and-forget — don't await, never blocks UI
      _updateUnreadAndNotify(room, uid, text);

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        _msgController.text = text;
        _snack('Failed: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _updateUnreadAndNotify(
      DocumentReference room, String senderUid, String text) async {
    try {
      final snap = await room.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participantIds'] ?? []);

      final Map<String, dynamic> updates = {};
      for (final pid in participants) {
        if (pid != senderUid) {
          updates['unreadCounts.$pid'] = FieldValue.increment(1);
        }
      }
      if (updates.isNotEmpty) await room.update(updates);

      for (final pid in participants) {
        if (pid == senderUid) continue;
        await NotificationTriggerService().onNewChatMessage(
          senderId: senderUid,
          receiverId: pid,
          chatRoomId: widget.chatRoomId,
          messagePreview: text,
        );
      }
    } catch (_) {}
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _deleteMessage(String docId, String senderId) async {
    if (_uid != senderId) {
      _snack('You can only delete your own messages.', Colors.orange);
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

  Future<void> _deleteChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Delete all messages? Cannot be undone.'),
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
      batch.update(_db.collection('chat_rooms').doc(widget.chatRoomId),
          {'lastMessage': null, 'lastMessageAt': Timestamp.now()});
      await batch.commit();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Capture uid once per build for bubble alignment
    final myUid = _uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('discuss_pickup'.tr(),
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: _deleteChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withValues(alpha: 0.08),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('chat_info_banner'.tr(),
                      style: const TextStyle(fontSize: 12, color: Colors.green))),
            ]),
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Use simple snapshot without orderBy — no index needed
              // Sort client-side instead
              stream: _db
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: Colors.red)));
                }

                final docs = List<QueryDocumentSnapshot>.from(
                    snap.data?.docs ?? []);
                // Sort ascending by sentAt client-side
                docs.sort((a, b) => _ts(a).compareTo(_ts(b)));
                return _buildList(docs, myUid, cs);
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 1,
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
                  // Enter key sends on web
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 4),
              // Send button
              Material(
                color: _sending ? Colors.grey : cs.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _sending ? null : _sendMessage,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs, String myUid, ColorScheme cs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('no_messages_yet'.tr(),
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text('Send the first message!',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final msg = MessageModel.fromMap(data, docs[i].id);
        final isMe = msg.senderId == myUid;
        return _Bubble(
          docId: docs[i].id,
          senderId: msg.senderId,
          text: msg.text,
          time: '${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
          isMe: isMe,
          onLongPress: _deleteMessage,
          colorScheme: cs,
        );
      },
    );
  }

  static int _ts(QueryDocumentSnapshot d) {
    final v = (d.data() as Map<String, dynamic>)['sentAt'];
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    return 0;
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────
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
          margin: EdgeInsets.only(
            bottom: 8,
            left: isMe ? 72 : 0,
            right: isMe ? 0 : 72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  style: TextStyle(
                      color: isMe ? Colors.white : colorScheme.onSurface,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(time,
                  style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white70
                          : colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
