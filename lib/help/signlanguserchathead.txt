import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_ease/signlanguserscreen/record_gesture.dart';
import 'package:sign_ease/utils/colors_utils.dart';

class SignLangUserChatHead extends StatefulWidget {
  const SignLangUserChatHead({
    Key? key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userEmails,
  }) : super(key: key);

  final String userId;
  final String userEmail;
  final String userName;
  final List<String> userEmails;

  @override
  State<SignLangUserChatHead> createState() => _SignLangUserChatHeadState();
}

class _SignLangUserChatHeadState extends State<SignLangUserChatHead> {
  final TextEditingController _controller = TextEditingController();
  Stream<QuerySnapshot>? _messagesStream;
  String? _chatRoomId;
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: const TextStyle(color: Colors.white70),
                fillColor: const Color.fromARGB(255, 7, 130, 230),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 40, // Reduced size
            width: 40, // Reduced size
            child: ElevatedButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  _sendMessage(_controller.text.trim());
                  _controller.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.blue,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 40, // Reduced size
            width: 40, // Reduced size
            child: ElevatedButton(
              onPressed: _navigateToRecordGesture,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.blue,
              ),
              child: const Icon(Icons.back_hand_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
    _initializeMessagesStream();
  }

  void _initializeChatRoom() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final otherUserId = widget.userId;

    _chatRoomId = currentUserId.compareTo(otherUserId) < 0
        ? '${currentUserId}_${otherUserId}'
        : '${otherUserId}_${currentUserId}';
  }

  void _initializeMessagesStream() {
    if (_chatRoomId == null) return;
    try {
      _messagesStream = FirebaseFirestore.instance
          .collection('universalMessages')
          .doc(_chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error initializing messages stream: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (_chatRoomId == null) return;

    final messageDoc = FirebaseFirestore.instance
        .collection('universalMessages')
        .doc(_chatRoomId)
        .collection('messages')
        .doc();

    await messageDoc.set({
      'message': message,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'sender': FirebaseAuth.instance.currentUser!.uid,
      'receiver': widget.userId,
    });

    final chatDocRef = FirebaseFirestore.instance
        .collection('universalChats')
        .doc(_chatRoomId);

    await chatDocRef.set({
      'participants': [
        FirebaseAuth.instance.currentUser!.uid,
        widget.userId,
      ],
      'lastMessage': message,
      'lastMessageType': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _navigateToRecordGesture() async {
    final String? predictedSign = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordGestureScreen()),
    );

    if (predictedSign != null && predictedSign.isNotEmpty) {
      _sendMessage(predictedSign);
    }
  }

  Future<void> _deleteMessage(String messageId, bool fromAll) async {
    if (_chatRoomId == null) return;

    try {
      final messageRef = FirebaseFirestore.instance
          .collection('universalMessages')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(messageId);

      if (fromAll) {
        await messageRef.delete();
      } else {
        await messageRef.update({
          'deletedFor':
              FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
        });
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _confirmDeleteMessage(String messageId, bool isCurrentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Do you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (isCurrentUser)
            TextButton(
              onPressed: () {
                _deleteMessage(messageId, true);
                Navigator.of(context).pop();
              },
              child: const Text('Delete for Everyone'),
            ),
          TextButton(
            onPressed: () {
              _deleteMessage(messageId, false);
              Navigator.of(context).pop();
            },
            child: const Text('Delete for Me'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: hexStringToColor("2986cc"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final messageData = doc.data() as Map<String, dynamic>;
                    final isCurrentUser = messageData['sender'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    final deletedFor = messageData['deletedFor'] ?? [];
                    final isDeletedForMe = deletedFor
                        .contains(FirebaseAuth.instance.currentUser!.uid);

                    if (isDeletedForMe) return SizedBox.shrink();

                    return GestureDetector(
                      onLongPress: () =>
                          _confirmDeleteMessage(doc.id, isCurrentUser),
                      child: Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.greenAccent.shade200
                                : Colors.blueAccent.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            messageData['message'],
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      backgroundColor: hexStringToColor("ffffff"),
    );
  }
}
