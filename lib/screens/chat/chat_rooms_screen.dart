import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';

/// Shows all chat rooms the current user is part of.
/// Used by both donors (My Chats) and NGOs (My Chats).
class ChatRoomsScreen extends StatelessWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('my_chats'.tr()),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participantIds', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('Error loading chats',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          // Filter out rooms with bad participantIds data
          final allDocs = snapshot.data?.docs ?? [];
          final rooms = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participantIds'] ?? []);
            // Must have at least 2 participants and the other one must be non-empty
            final otherUid = participants.firstWhere(
              (id) => id != uid && id.isNotEmpty,
              orElse: () => '',
            );
            return otherUid.isNotEmpty;
          }).toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aLast = aData['lastMessageAt'];
              final bLast = bData['lastMessageAt'];
              final aMs = aLast is Timestamp ? aLast.millisecondsSinceEpoch : 0;
              final bMs = bLast is Timestamp ? bLast.millisecondsSinceEpoch : 0;
              return bMs.compareTo(aMs);
            });

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'no_chats_yet'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'chats_appear_after_claim'.tr(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;
              final roomId = rooms[index].id;
              final participants =
                  List<String>.from(data['participantIds'] ?? []);
              final otherUid = participants.firstWhere(
                (id) => id != uid && id.isNotEmpty,
                orElse: () => '',
              );

              final lastMsg = data['lastMessage'] as String? ?? '';
              final unread = (data['unreadCounts']
                          as Map<String, dynamic>?)?[uid]
                      as int? ??
                  0;
              final lastAt = data['lastMessageAt'];
              String timeStr = '';
              if (lastAt is Timestamp) {
                final dt = lastAt.toDate();
                timeStr =
                    '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid) // safe — filtered empty above
                    .get(),
                builder: (context, userSnap) {
                  String otherName = 'Loading...';
                  if (userSnap.hasData) {
                    if (userSnap.data!.exists) {
                      final d =
                          userSnap.data!.data() as Map<String, dynamic>;
                      otherName = (d['organizationName'] ??
                              d['userName'] ??
                              d['email'] ??
                              'User')
                          .toString();
                    } else {
                      otherName = 'User';
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      lastMsg.isEmpty ? 'tap_to_chat'.tr() : lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(timeStr,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        if (unread > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .doc(roomId)
                          .update({'unreadCounts.$uid': 0})
                          .catchError((_) {});

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoomId: roomId,
                            otherUserName: otherName,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _confirmDeleteChat(context, roomId, otherName),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

void _confirmDeleteChat(
    BuildContext context, String roomId, String otherName) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.delete_outline, color: Colors.red),
        SizedBox(width: 8),
        Text('Delete Chat'),
      ]),
      content: Text(
          'Delete your chat with $otherName?\nThis cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              final db = FirebaseFirestore.instance;
              final msgs = await db
                  .collection('chat_rooms')
                  .doc(roomId)
                  .collection('messages')
                  .get();
              final batch = db.batch();
              for (final d in msgs.docs) {
                batch.delete(d.reference);
              }
              batch.delete(db.collection('chat_rooms').doc(roomId));
              await batch.commit();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
