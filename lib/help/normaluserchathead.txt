import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_ease/utils/colors_utils.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NormalUserChatHead extends StatefulWidget {
  const NormalUserChatHead({
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
  State<NormalUserChatHead> createState() => _NormalUserChatHeadState();
}

class _NormalUserChatHeadState extends State<NormalUserChatHead> {
  final TextEditingController _controller = TextEditingController();
  Stream<QuerySnapshot>? _messagesStream;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String? _chatRoomId;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  void _initializeChatRoom() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final otherUserId = widget.userId;

    _chatRoomId = currentUserId.compareTo(otherUserId) < 0
        ? '${currentUserId}_$otherUserId'
        : '${otherUserId}_${currentUserId}';

    try {
      final chatRoomDoc = FirebaseFirestore.instance
          .collection('universalChats')
          .doc(_chatRoomId);

      final chatExists = (await chatRoomDoc.get()).exists;
      if (!chatExists) {
        await chatRoomDoc.set({
          'participants': [currentUserId, otherUserId],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _initializeMessagesStream();
    } catch (e) {
      print('Error initializing ChatRoom: $e');
    }
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

      setState(() {});
    } catch (e) {
      print('Error initializing messages stream: $e');
    }
  }

  Future<void> _saveMessage(String message) async {
    if (_chatRoomId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final messageDoc = FirebaseFirestore.instance
          .collection('universalMessages')
          .doc(_chatRoomId)
          .collection('messages')
          .doc();

      await messageDoc.set({
        'message': message,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'sender': currentUserId,
        'receiver': widget.userId,
      });

      final chatDocRef = FirebaseFirestore.instance
          .collection('universalChats')
          .doc(_chatRoomId);

      await chatDocRef.set({
        'participants': [currentUserId, widget.userId],
        'lastMessage': message,
        'lastMessageType': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      _saveMessage(message).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $error')),
        );
      });
      _controller.clear();
    }
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == "notListening") {
            // Stop listening and save the accumulated message
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          print('Speech error: $error');
          setState(() {
            _isListening = false;
          });
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
        });

        String accumulatedResult =
            ""; // Variable to accumulate the speech result

        _speech.listen(
          onResult: (result) {
            // Accumulate the result as the user speaks
            accumulatedResult = result.recognizedWords;
            print("Current Speech Result: $accumulatedResult");
          },
          listenFor: const Duration(seconds: 60), // Maximum session duration
          pauseFor: const Duration(seconds: 2), // Auto-stop after a pause
          partialResults: true, // Allow partial results
        );

        // Stop and save the accumulated result when the session ends
        _speech.statusListener = (status) {
          if (status == "notListening" && accumulatedResult.isNotEmpty) {
            _speech.stop();
            setState(() {
              _isListening = false;
            });
            _saveMessage(accumulatedResult); // Save the entire message
          }
        };
      } else {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition unavailable')),
        );
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    if (_chatRoomId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('universalMessages')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(messageId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
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

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData =
                      messages[index].data() as Map<String, dynamic>;
                  final sender = messageData['sender'];
                  final isCurrentUser =
                      sender == FirebaseAuth.instance.currentUser!.uid;

                  return GestureDetector(
                    onLongPress: () =>
                        _confirmDeleteMessage(messages[index].id),
                    child: _buildMessageBubble(
                      messageData['message'],
                      isCurrentUser,
                    ),
                  );
                },
              );
            },
          )),
          _buildMessageInput(),
        ],
      ),
      backgroundColor: hexStringToColor("ffffff"),
    );
  }

  Widget _buildMessageBubble(String message, bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Colors.greenAccent.shade200
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Text(message, style: const TextStyle(color: Colors.black)),
      ),
    );
  }

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
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: hexStringToColor("2986cc"),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
              onPressed: _toggleListening,
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: hexStringToColor("2986cc"),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
