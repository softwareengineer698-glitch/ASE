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
    if (uid == null) {
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rooms =
              List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? [])
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aLast = aData['lastMessageAt'];
                  final bLast = bData['lastMessageAt'];
                  final aMillis =
                      aLast is Timestamp ? aLast.millisecondsSinceEpoch : 0;
                  final bMillis =
                      bLast is Timestamp ? bLast.millisecondsSinceEpoch : 0;
                  return bMillis.compareTo(aMillis);
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
              final otherUid =
                  participants.firstWhere((id) => id != uid, orElse: () => '');
              final lastMsg = data['lastMessage'] as String? ?? '';
              final unread = (data['unreadCounts']
                      as Map<String, dynamic>?)?[uid] as int? ??
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
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnap) {
                  final otherName = userSnap.hasData && userSnap.data!.exists
                      ? ((userSnap.data!.data()
                              as Map<String, dynamic>)['userName'] ??
                          (userSnap.data!.data()
                              as Map<String, dynamic>)['email'] ??
                          'User')
                      : 'Loading...';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
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
                      // Clear unread count
                      FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .doc(roomId)
                          .update({'unreadCounts.$uid': 0});

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
