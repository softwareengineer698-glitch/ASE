import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_ease/normaluserscreens/normaluserchathead.dart';
import 'package:sign_ease/signlanguserscreen/SignLangUser.dart';
import 'package:sign_ease/signlanguserscreen/SignLangUserChatHead.dart';
import 'package:sign_ease/resuable_widgets/reusable_widget.dart';
import 'package:sign_ease/utils/colors_utils.dart';

class StartChatSL extends StatefulWidget {
  const StartChatSL({super.key});

  @override
  State<StartChatSL> createState() => _StartChatSLState();
}

class _StartChatSLState extends State<StartChatSL> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? selectedUserType;

  Future<void> _startChat() async {
    String userEmail = _emailController.text.trim();
    String userName = _nameController.text.trim();

    // Validate input
    if (userEmail.isEmpty || userName.isEmpty || selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields and select a user type'),
        ),
      );
      return;
    }

    try {
      // Query Firestore to find the user by email in the 'users' collection
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email')),
        );
        return;
      }

      // Get the user's UID and verify the username
      var userDoc = userQuery.docs.first;
      String uid = userDoc.id;
      String fetchedUsername = userDoc['username'];
      String actualUserType = userDoc['userType'];

      // Check if the username matches
      if (fetchedUsername.toLowerCase() != userName.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username does not match the email')),
        );
        return;
      }

      // Check if selected user type matches actual user type
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
          ? '${currentUserId}_${uid}'
          : '${uid}_${currentUserId}';

      final chatDoc =
          FirebaseFirestore.instance.collection('universalChats').doc(chatId);

      // Check if the chat exists
      final chatExists = (await chatDoc.get()).exists;

      // If no existing chat, create a new one
      if (!chatExists) {
        await chatDoc.set({
          'participants': [currentUserId, uid],
          'lastMessage': '', // Placeholder for the last message
          'lastMessageType': '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Pop the current screen to go back to SignLangUser
      Navigator.pop(context); // This will navigate back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
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
