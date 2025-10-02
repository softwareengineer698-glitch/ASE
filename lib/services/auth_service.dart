import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth {
    if (_auth == null) {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized. Please ensure Firebase.initializeApp() is called first.');
      }
      _auth = FirebaseAuth.instance;
    }
    return _auth!;
  }

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized. Please ensure Firebase.initializeApp() is called first.');
      }
      _firestore = FirebaseFirestore.instance;
    }
    return _firestore!;
  }

  // Check if Firebase is initialized
  bool get isFirebaseInitialized {
    return Firebase.apps.isNotEmpty;
  }

  // Get current user
  User? get currentUser => auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      print('Starting sign up process for email: $email');
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print('User created successfully, creating Firestore document...');
        // Create user document in Firestore
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          role: role,
          createdAt: DateTime.now(),
        );

        await firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        print('Firestore document created, saving role locally...');
        // Save user role locally
        await _saveUserRole(role);

        print('Sign up completed successfully');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during sign up: $e');
      throw 'Account creation failed: $e';
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Get user data from Firestore
        UserModel? userModel = await getUserData(user.uid);
        if (userModel != null) {
          // Save user role locally
          await _saveUserRole(userModel.role);
        }
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      await _clearUserRole();
    } catch (e) {
      throw 'Error signing out. Please try again.';
    }
  }

  // Save user role locally
  Future<void> _saveUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role.name);
  }

  // Get saved user role
  Future<UserRole?> getSavedUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('user_role');
    if (roleString != null) {
      return UserRole.values.firstWhere(
        (e) => e.name == roleString,
        orElse: () => UserRole.donor,
      );
    }
    return null;
  }

  // Clear saved user role
  Future<void> _clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
