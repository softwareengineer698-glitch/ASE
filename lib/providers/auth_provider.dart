import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
    // Don't initialize immediately, wait for explicit call
    print('AuthProvider created, waiting for Firebase to be ready');
    // Try to initialize with longer delay and retry mechanism
    _waitForFirebaseAndInitialize();
  }

  void _waitForFirebaseAndInitialize() async {
    // Wait for Firebase to be initialized with retry mechanism
    int attempts = 0;
    const maxAttempts = 10;
    const delayBetweenAttempts = Duration(milliseconds: 500);

    while (attempts < maxAttempts) {
      if (_authService.isFirebaseInitialized) {
        print('Firebase is ready after $attempts attempts, initializing auth');
        _initializeAuth();
        return;
      }
      
      attempts++;
      print('Firebase not ready yet, attempt $attempts/$maxAttempts');
      await Future.delayed(delayBetweenAttempts);
    }
    
    print('Firebase initialization timeout after $maxAttempts attempts');
  }

  void _initializeAuth() {
    // Initialize auth state listener if Firebase is available
    if (_authService.isFirebaseInitialized) {
      print('Firebase is ready, setting up auth state listener');
      _setupAuthStateListener();
    } else {
      print('Firebase not ready yet in AuthProvider');
    }
  }

  void _setupAuthStateListener() {
    try {
      _authService.authStateChanges.listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          _user = await _authService.getUserData(firebaseUser.uid);
        } else {
          _user = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error setting up auth state listener: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        role: role,
      );
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
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

  // Reinitialize auth after Firebase is ready
  void reinitializeAuth() {
    if (!_authService.isFirebaseInitialized) {
      print('Firebase not initialized yet, skipping auth state listener setup');
      return;
    }
    
    _setupAuthStateListener();
  }
}
