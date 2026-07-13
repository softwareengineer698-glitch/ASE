import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_ease/normaluserscreens/NormalUser.dart'; // Import the NormalUser screen
import 'package:sign_ease/resuable_widgets/reusable_widget.dart';
import 'package:sign_ease/utils/colors_utils.dart';

class StartChatNL extends StatefulWidget {
  const StartChatNL({super.key});

  @override
  State<StartChatNL> createState() => _StartChatNLState();
}

class _StartChatNLState extends State<StartChatNL> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? selectedUserType;
  String? currentUserType;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserType();
  }

  Future<void> _fetchCurrentUserType() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        setState(() {
          currentUserType = userDoc['userType'] ?? 'Unknown';
        });
      }
    } catch (e) {
      print("Error fetching current user type: $e");
    }
  }

  Future<void> _startChat() async {
    String userEmail = _emailController.text.trim();
    String userName = _nameController.text.trim();

    if (userEmail.isEmpty || userName.isEmpty || selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields and select a user type.'),
        ),
      );
      return;
    }

    try {
      // Query Firestore to find the user with the provided email
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email.')),
        );
        return;
      }

      // Fetch the user data
      var userDoc = userQuery.docs.first;
      String uid = userDoc.id;
      String fetchedUsername = userDoc['username'];
      String actualUserType = userDoc['userType'];

      if (fetchedUsername.toLowerCase() != userName.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username does not match the email.')),
        );
        return;
      }

      if (actualUserType != selectedUserType) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User type mismatch. Selected: $selectedUserType, Actual: $actualUserType',
            ),
          ),
        );
        return;
      }

      // Generate a universal chat ID
      final chatId = (currentUserId.compareTo(uid) < 0)
          ? '${currentUserId}_$uid'
          : '${uid}_$currentUserId';

      final chatDoc =
          FirebaseFirestore.instance.collection('universalChats').doc(chatId);

      // Check if the chat exists
      final chatExists = (await chatDoc.get()).exists;

      // If no existing chat, create a new one
      if (!chatExists) {
        await chatDoc.set({
          'participants': [currentUserId, uid],
          'lastMessage': '',
          'lastMessageType': '',
          'timestamp': FieldValue.serverTimestamp(),
          'userTypes': {
            currentUserId: currentUserType ?? 'Unknown',
            uid: actualUserType,
          },
          'userEmails': {
            currentUserId: FirebaseAuth.instance.currentUser!.email,
            uid: userEmail,
          },
          'userNames': {
            currentUserId:
                FirebaseAuth.instance.currentUser!.displayName ?? 'Unknown',
            uid: fetchedUsername,
          }
        });
      }

      // Pop the current screen and return to the previous screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: hexStringToColor("ffffff"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Start New Chat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 7, 130, 230),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  'Email',
                  Icons.email,
                  false,
                  _emailController,
                ),
                const SizedBox(height: 16),
                reusableTextField(
                  'Name',
                  Icons.person,
                  false,
                  _nameController,
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedUserType,
                  hint: const Text('Select User Type'),
                  items: <String>['Sign Language User', 'Normal User']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedUserType = newValue;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startChat,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color.fromARGB(255, 7, 130, 230),
                  ),
                  child: const Text(
                    'Start Chat',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
