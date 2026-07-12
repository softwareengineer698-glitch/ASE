import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// Only import google_sign_in on non-web platforms
import 'google_sign_in_helper.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kDebugMode ? Level.debug : Level.warning,
);

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  ConfirmationResult? _webPhoneConfirmation;

  FirebaseAuth get auth {
    if (_auth == null) {
      if (Firebase.apps.isEmpty) {
        throw Exception(
            'Firebase not initialized. Please ensure Firebase.initializeApp() is called first.');
      }
      _auth = FirebaseAuth.instance;
    }
    return _auth!;
  }

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      if (Firebase.apps.isEmpty) {
        throw Exception(
            'Firebase not initialized. Please ensure Firebase.initializeApp() is called first.');
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
    String? userName,
    String? phoneNumber,
  }) async {
    try {
      _log.d('Starting sign up process for email: $email');
      final UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        _log.d('User created successfully, creating Firestore document...');
        final UserModel userModel = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          userName: userName,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
        );

        final firestoreData = {
          ...userModel.toMap(),
          // Also store as 'name' and 'phone' so profile screens can read them
          'name': userName ?? '',
          'phone': phoneNumber ?? '',
        };
        _log.d('Firestore data → doc: ${user.uid}, email: ${user.email}');

        await firestore.collection('users').doc(user.uid).set(firestoreData);

        _log.d('Firestore document created, saving role locally...');
        await _saveUserRole(role);

        _log.d('Sign up completed successfully');
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _log.e('FirebaseAuthException during sign up: ${e.code}', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      _log.e('Unexpected error during sign up', error: e);
      throw 'auth_error_account_creation_failed';
    }
  }

  /// Completes email/password registration after phone OTP verification.
  /// The current Firebase user is the phone-auth user; this links the email
  /// credential to that same account and writes the verified user document.
  Future<UserModel> completeVerifiedEmailSignUp({
    required String email,
    required String password,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) throw 'auth_error_phone_sign_in_empty';
      var verifiedUser = currentUser;

      final emailCredential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      try {
        final linked = await verifiedUser.linkWithCredential(emailCredential);
        verifiedUser = linked.user ?? verifiedUser;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use' ||
            e.code == 'credential-already-in-use') {
          throw 'auth_error_email_already_in_use';
        }
        if (e.code != 'provider-already-linked') {
          throw _handleAuthException(e);
        }
      }

      await verifiedUser.updateDisplayName(userName);

      final userModel = UserModel(
        uid: verifiedUser.uid,
        email: email,
        userName: userName,
        phoneNumber: phoneNumber,
        phoneVerified: true,
        role: UserRole.donor,
        createdAt: DateTime.now(),
      );

      await firestore.collection('users').doc(verifiedUser.uid).set(
            userModel.toMap(),
            SetOptions(merge: true),
          );
      await _saveUserRole(UserRole.donor);
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'auth_error_account_creation_failed';
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Developer Bypass for Admin Login that integrates with real Firebase Auth
      if ((email == 'admin@foodbridge.com' || email == 'admin') &&
          password == 'admin123') {
        final adminEmail = email.contains('@') ? email : 'admin@foodbridge.com';
        try {
          _log.d('Attempting admin sign-in with Firebase Auth...');
          final UserCredential result = await auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: password,
          );
          final User? user = result.user;
          if (user != null) {
            UserModel? userModel = await getUserData(user.uid);
            if (userModel == null) {
              userModel = UserModel(
                uid: user.uid,
                email: adminEmail,
                role: UserRole.admin,
                createdAt: DateTime.now(),
                userName: 'System Admin',
                isVerified: true,
              );
              await firestore
                  .collection('users')
                  .doc(user.uid)
                  .set(userModel.toMap());
            }
            await _saveUserRole(UserRole.admin);
            return userModel;
          }
        } catch (authError) {
          _log.w(
              'Firebase Auth admin sign-in failed: $authError. Attempting auto-registration...');
          try {
            final UserCredential result =
                await auth.createUserWithEmailAndPassword(
              email: adminEmail,
              password: password,
            );
            final User? user = result.user;
            if (user != null) {
              final UserModel userModel = UserModel(
                uid: user.uid,
                email: adminEmail,
                role: UserRole.admin,
                createdAt: DateTime.now(),
                userName: 'System Admin',
                isVerified: true,
              );
              await firestore
                  .collection('users')
                  .doc(user.uid)
                  .set(userModel.toMap());
              await _saveUserRole(UserRole.admin);
              return userModel;
            }
          } catch (createError) {
            _log.w(
                'Firebase Auth admin creation failed: $createError. Falling back to offline bypass...');
            return UserModel(
              uid: 'admin_bypass_id_777',
              email: adminEmail,
              role: UserRole.admin,
              createdAt: DateTime.now(),
              userName: 'System Admin',
              isVerified: true,
            );
          }
        }
      }

      final UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        final UserModel? userModel = await getUserData(user.uid);
        if (userModel != null) {
          await _saveUserRole(userModel.role);
        }
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'auth_error_unexpected';
    }
  }

  // Sign in with Google — works on both Web and Mobile
  // Always returns isNewUser=true so the caller shows the role picker.
  // For returning users, the existing role is pre-selected in the picker.
  Future<({UserModel? user, bool isNewUser})> signInWithGoogle() async {
    try {
      UserCredential result;

      if (kIsWeb) {
        // ── Web: use Firebase popup flow ──────────────────────────────
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        result = await auth.signInWithPopup(googleProvider);
      } else {
        // ── Mobile: use google_sign_in package ────────────────────────
        result = await GoogleSignInHelper.signInWithCredential(auth);
        // Returns empty credential if user cancelled
        if (result.user == null) return (user: null, isNewUser: false);
      }

      final User? firebaseUser = result.user;
      if (firebaseUser == null) return (user: null, isNewUser: false);

      // Check if user already exists in Firestore
      final existingDoc =
          await firestore.collection('users').doc(firebaseUser.uid).get();

      if (existingDoc.exists) {
        // Returning user — load their saved role; we still show the
        // role picker so they can switch if needed.
        final userModel =
            UserModel.fromMap(existingDoc.data() as Map<String, dynamic>);
        return (user: userModel, isNewUser: false);
      } else {
        // Brand-new Google user — create stub Firestore doc.
        // Role will be updated after the user makes their selection.
        final userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          role: UserRole.donor, // placeholder; updated in updateUserRole()
          createdAt: DateTime.now(),
          userName: firebaseUser.displayName,
        );
        await firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          ...userModel.toMap(),
          // Store as 'name' and 'email' so profile screens can read them
          'name': firebaseUser.displayName ?? '',
          'phone': '',
        });
        return (user: userModel, isNewUser: true);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'auth_error_google_sign_in_failed';
    }
  }

  // Update a user's role in Firestore and locally
  Future<UserModel?> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    try {
      await firestore.collection('users').doc(uid).update({
        'role': role.name,
        'roleSelected': true,
      });
      await _saveUserRole(role);
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to update role: $e';
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _log.e('Error getting user data for $uid', error: e);
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
      throw 'auth_error_unexpected';
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

  // ── Phone / OTP Authentication ─────────────────────────────────────────────

  /// Step 1: Send OTP to [phoneNumber] (E.164 format, e.g. +923001234567).
  /// On Android the OTP may be auto-retrieved; [onAutoVerified] fires in that
  /// case so the UI can skip the manual entry step.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    int? resendToken,
  }) async {
    if (kIsWeb) {
      _webPhoneConfirmation = await auth.signInWithPhoneNumber(phoneNumber);
      onCodeSent('web-phone-confirmation', null);
      return;
    }

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Android auto-retrieval / instant verification
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(_handleAuthException(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Step 2: Verify the [smsCode] against [verificationId] returned by [sendOtp].
  /// Creates or loads the Firestore user document, sets [phoneVerified] = true,
  /// and returns the [UserModel].
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
    String? userName,
  }) async {
    if (kIsWeb) {
      final confirmation = _webPhoneConfirmation;
      if (confirmation == null) throw 'otp_expired';
      final result = await confirmation.confirm(smsCode);
      final firebaseUser = result.user;
      if (firebaseUser == null) throw 'auth_error_phone_sign_in_empty';
      _webPhoneConfirmation = null;
      return _syncPhoneUser(firebaseUser, userName: userName);
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _signInWithPhoneCredential(credential, userName: userName);
  }

  /// Signs in with an already-built [PhoneAuthCredential] (used by both
  /// manual OTP entry and Android auto-verification).
  Future<UserModel> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    return _signInWithPhoneCredential(credential);
  }

  Future<UserModel> _syncPhoneUser(
    User firebaseUser, {
    String? userName,
  }) async {
    final docRef = firestore.collection('users').doc(firebaseUser.uid);
    final snap = await docRef.get();

    if (snap.exists) {
      final existing = UserModel.fromMap(snap.data() as Map<String, dynamic>);
      if (!existing.phoneVerified) {
        await docRef.update({
          'phoneNumber': firebaseUser.phoneNumber,
          'phoneVerified': true,
        });
      }
      await _saveUserRole(existing.role);
      return existing.copyWith(
        phoneNumber: firebaseUser.phoneNumber,
        phoneVerified: true,
      );
    }

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      role: UserRole.donor,
      createdAt: DateTime.now(),
      userName: userName ?? firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      phoneVerified: true,
    );
    await docRef.set(userModel.toMap());
    await _saveUserRole(UserRole.donor);
    return userModel;
  }
  Future<UserModel> _signInWithPhoneCredential(
    PhoneAuthCredential credential, {
    String? userName,
  }) async {
    final result = await auth.signInWithCredential(credential);
    final firebaseUser = result.user;
    if (firebaseUser == null) throw 'auth_error_phone_sign_in_empty';
    return _syncPhoneUser(firebaseUser, userName: userName);
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'auth_error_weak_password';
      case 'email-already-in-use':
        return 'auth_error_email_already_in_use';
      case 'user-not-found':
        return 'auth_error_user_not_found';
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_error_wrong_password';
      case 'invalid-email':
        return 'auth_error_invalid_email';
      case 'user-disabled':
        return 'auth_error_user_disabled';
      case 'too-many-requests':
        return 'auth_error_too_many_requests';
      case 'operation-not-allowed':
        return 'auth_error_operation_not_allowed';
      case 'invalid-verification-code':
        return 'invalid_otp';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'otp_expired';
      case 'invalid-phone-number':
        return 'invalid_phone_number';
      case 'quota-exceeded':
        return 'auth_error_sms_quota_exceeded';
      case 'network-request-failed':
        return 'auth_error_network';
      default:
        return 'auth_error_generic';
    }
  }
}

