import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Check if Firebase is available
  bool get isFirebaseAvailable => _authService.isFirebaseInitialized;

  AuthProvider() {
    _waitForFirebaseAndInitialize();
  }

  Future<void> _waitForFirebaseAndInitialize() async {
    // Wait for Firebase to be initialized with retry mechanism
    int attempts = 0;
    const maxAttempts = 8;
    const delayBetweenAttempts = Duration(milliseconds: 400);

    while (attempts < maxAttempts) {
      if (_authService.isFirebaseInitialized) {
        _initializeAuth();
        return;
      }

      attempts++;
      await Future.delayed(delayBetweenAttempts);
    }

    debugPrint('Firebase initialization timeout after $maxAttempts attempts');
  }

  void _initializeAuth() {
    // Initialize auth state listener if Firebase is available
    if (_authService.isFirebaseInitialized) {
      _setupAuthStateListener();
    }
  }

  void _setupAuthStateListener() {
    try {
      _authService.authStateChanges.listen(
        (User? firebaseUser) async {
          try {
            if (firebaseUser != null) {
              _user = await _authService.getUserData(firebaseUser.uid);
            } else {
              _user = null;
            }
          } catch (e) {
            debugPrint('Error loading user data: $e');
            _user = null;
          } finally {
            _isLoading = false;
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Auth state stream error: $e');
          _user = null;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error setting up auth state listener: $e');
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? userName,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        role: role,
        userName: userName,
        phoneNumber: phoneNumber,
      );

      notifyListeners();
      return _user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> completeVerifiedEmailSignUp({
    required String email,
    required String password,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _user = await _authService.completeVerifiedEmailSignUp(
        email: email,
        password: password,
        userName: userName,
        phoneNumber: phoneNumber,
      );
      notifyListeners();
      return _user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      notifyListeners();
      // Refresh FCM token now that a user is signed in
      _refreshFcmToken();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Returns the [UserModel] after Google OAuth. The caller is responsible
  /// for showing the role picker and calling [updateUserRole] afterwards.
  Future<({UserModel? user, bool isNewUser})?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.signInWithGoogle();
      _user = result.user;
      notifyListeners();
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserRole(UserRole role) async {
    if (_user == null) return;
    try {
      _setLoading(true);
      _clearError();
      _user = await _authService.updateUserRole(uid: _user!.uid, role: role);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<UserRole?> getSavedUserRole() async {
    return await _authService.getSavedUserRole();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // ── Phone / OTP ────────────────────────────────────────────────────────────

  /// [phoneVerified] exposes whether the current user's phone is verified.
  bool get phoneVerified => _user?.phoneVerified ?? false;

  /// Step 1 – send OTP. Calls back [onCodeSent] with the verificationId
  /// that must be passed to [verifyOtp]. Does NOT change [isLoading] so
  /// callers can manage their own loading state.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    int? resendToken,
  }) async {
    try {
      _clearError();
      await _authService.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onFailed: (error) {
          _setError(error);
          onFailed(error);
        },
        onAutoVerified: onAutoVerified,
        resendToken: resendToken,
      );
    } catch (e) {
      final error = e.toString();
      _setError(error);
      onFailed(error);
    }
  }

  /// Step 2 – verify OTP. Returns the resulting [UserModel] for the caller
  /// to decide whether to show the role picker.
  Future<UserModel?> verifyOtp({
    required String verificationId,
    required String smsCode,
    String? userName,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _user = await _authService.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        userName: userName,
      );
      notifyListeners();
      return _user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Called after Android auto-verification completes.
  Future<UserModel?> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      _setLoading(true);
      _clearError();
      _user = await _authService.signInWithPhoneCredential(credential);
      notifyListeners();
      return _user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Reinitialize auth after Firebase is ready
  void reinitializeAuth() {
    if (!_authService.isFirebaseInitialized) {
      return;
    }
    _setupAuthStateListener();
  }

  /// Sends a verification email to the currently signed-in user.
  Future<void> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('sendEmailVerification error: $e');
    }
  }

  // Refresh FCM token after login
  void _refreshFcmToken() {
    // Delegate to NotificationService which has the token-save logic
    NotificationService()
        .initializeFCM()
        .catchError((e) => debugPrint('FCM token refresh error: $e'));
  }
}
