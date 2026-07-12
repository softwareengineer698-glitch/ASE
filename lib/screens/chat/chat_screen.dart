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
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  // Always get uid directly from FirebaseAuth — never stale
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    print('💬💬💬 ChatScreen initialized - CODE v3.0 LOADED 💬💬💬');
    debugPrint('💬 ChatScreen initialized - NEW CODE LOADED ✅');
    debugPrint('💬 Room: ${widget.chatRoomId}, Other user: ${widget.otherUserName}');
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    print('🟡🟡🟡 _sendMessage ENTRY 🟡🟡🟡');
    print('_isSending = $_isSending');
    
    if (_isSending) {
      print('⚠️ Already sending, ignoring duplicate call');
      return;
    }
    
    print('Setting _isSending to true...');
    setState(() => _isSending = true);
    
    final text = _msgController.text.trim();
    print('💬 Message text: "$text"');
    print('💬 UID: "$_uid"');
    print('💬 Room: "${widget.chatRoomId}"');
    
    if (text.isEmpty) {
      print('💬 Text is empty, returning');
      setState(() => _isSending = false);
      return;
    }

    final currentUid = _uid;
    if (currentUid.isEmpty) {
      print('💬 UID is empty - user not signed in');
      _showSnack('Please sign in to send messages.', Colors.red);
      setState(() => _isSending = false);
      return;
    }

    print('💬 Clearing text field...');
    final messageToSend = text;
    _msgController.clear();

    try {
      final roomRef = _db.collection('chat_rooms').doc(widget.chatRoomId);
      final now = Timestamp.now();

      print('💬 Writing message to Firestore at ${roomRef.path}/messages...');
      debugPrint('💬 Writing message to Firestore at ${roomRef.path}/messages...');
      // Write message
      final docRef = await roomRef.collection('messages').add({
        'senderId': currentUid,
        'text': messageToSend,
        'sentAt': now,
        'isRead': false,
      });
      print('💬 ✅ Message written successfully: ${docRef.id}');
      debugPrint('💬 ✅ Message written successfully: ${docRef.id}');

      // Update room last message
      print('💬 Updating room last message...');
      debugPrint('💬 Updating room last message...');
      await roomRef.set({
        'lastMessage': messageToSend,
        'lastMessageAt': now,
        'unreadCounts': {currentUid: 0},
      }, SetOptions(merge: true));
      print('💬 ✅ Room updated successfully');
      debugPrint('💬 ✅ Room updated successfully');

      // Show success feedback
      if (mounted) {
        _showSnack('Message sent!', Colors.green);
      }

      // Increment unread + send notification (fire-and-forget)
      _postSendUpdates(roomRef, currentUid, messageToSend);

      _scrollToBottom();
    } catch (e, st) {
      print('💬 ❌ Send error: $e\n$st');
      debugPrint('💬 ❌ Send error: $e\n$st');
      if (mounted) {
        _msgController.text = messageToSend;
        _showSnack('Failed to send: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
    print('🟢 _sendMessage EXIT');
  }

  Future<void> _postSendUpdates(
      DocumentReference roomRef, String senderUid, String text) async {
    try {
      final snap = await roomRef.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final participants =
          List<String>.from(data['participantIds'] ?? []);

      // Increment unread counts for others
      final updates = <String, dynamic>{};
      for (final pid in participants) {
        if (pid != senderUid) {
          updates['unreadCounts.$pid'] = FieldValue.increment(1);
        }
      }
      if (updates.isNotEmpty) await roomRef.update(updates);

      // Send push notification to others
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

  Future<void> _deleteMessage(String docId, String senderId) async {
    if (_uid != senderId) {
      _showSnack('You can only delete your own messages.', Colors.orange);
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
        content: const Text('Delete all messages? This cannot be undone.'),
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
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.otherUserName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Row(
            children: [
              Text('discuss_pickup'.tr(),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white70)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'v2.0',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: 'Delete chat',
            onPressed: _deleteEntireChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withValues(alpha: 0.08),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text('chat_info_banner'.tr(),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.green)),
              ),
            ]),
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  // No orderBy — avoids composite index requirement
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 40),
                          const SizedBox(height: 12),
                          Text('Error: ${snap.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                }

                final docs =
                    List<QueryDocumentSnapshot>.from(snap.data?.docs ?? []);

                // Sort client-side by sentAt
                docs.sort((a, b) {
                  final aTime = _tsToMs(
                      (a.data() as Map<String, dynamic>)['sentAt']);
                  final bTime = _tsToMs(
                      (b.data() as Map<String, dynamic>)['sentAt']);
                  return aTime.compareTo(bTime);
                });

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
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final msg =
                        MessageModel.fromMap(data, docs[i].id);
                    final isMe = msg.senderId == _uid;
                    return _Bubble(
                      docId: docs[i].id,
                      senderId: msg.senderId,
                      text: msg.text,
                      time:
                          '${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                      isMe: isMe,
                      onLongPress: _deleteMessage,
                      colorScheme: colorScheme,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Row(children: [
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
                  onSubmitted: (_) {
                    print('🟣🟣🟣 TEXTFIELD ONSUBMITTED (ENTER KEY) 🟣🟣🟣');
                    print('Text: "${_msgController.text}"');
                    _sendMessage();
                  },
                  onChanged: (value) {
                    print('TextField value: "$value"');
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  print('🔴🔴🔴 ELEVATED BUTTON PRESSED 🔴🔴🔴');
                  print('Text: "${_msgController.text}"');
                  print('About to call _sendMessage()...');
                  try {
                    _sendMessage();
                    print('_sendMessage() returned');
                  } catch (e) {
                    print('ERROR calling _sendMessage: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  static int _tsToMs(dynamic v) {
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
