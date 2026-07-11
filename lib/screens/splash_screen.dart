import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'auth/sign_in_screen.dart';
import 'main/main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthState();
  }

  void _initializeAnimations() {
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Rotation animation controller
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    // Scale animation with bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Slide animation for text
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    ));

    // Pulse animation for icon
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for background elements
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start animations
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _checkAuthState() async {
    try {
      // Wait for splash animation to play (2s)
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;

      // ── Handle email sign-in link (web only) ──────────────────────────────
      // When user clicks the email OTP sign-in link, the app opens with the
      // link URL. Detect it here and complete the sign-in before anything else.
      if (kIsWeb) {
        try {
          final auth = FirebaseAuth.instance;
          // Get the current page URL on web
          // ignore: undefined_prefixed_name
          final currentUrl = Uri.base.toString();
          if (auth.isSignInWithEmailLink(currentUrl)) {
            // Get the email stored before sending the link
            final user = auth.currentUser;
            // Try to get email from current user or from the link itself
            String? emailForSignIn = user?.email;

            if (emailForSignIn != null && emailForSignIn.isNotEmpty) {
              final result = await auth.signInWithEmailLink(
                email: emailForSignIn,
                emailLink: currentUrl,
              );
              if (result.user != null && mounted) {
                await result.user!.reload();
                // Mark verified in Firestore
                try {
                  await _markEmailVerified(result.user!);
                } catch (_) {}
                // Navigate to main app — role picker handled by MainWrapper
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainWrapper()),
                  );
                  return;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Email link sign-in error (non-fatal): $e');
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Try to reinitialize auth — wrapped so it can never crash us
      try {
        if (authProvider.isFirebaseAvailable) {
          authProvider.reinitializeAuth();
          // Wait up to 3s for Firebase auth state to settle
          for (int i = 0; i < 30; i++) {
            if (!authProvider.isLoading) break;
            await Future.delayed(const Duration(milliseconds: 100));
            if (!mounted) return;
          }
        }
      } catch (e) {
        debugPrint('Auth reinit error (non-fatal): $e');
      }

      if (!mounted) return;

      // Navigate based on auth state
      if (authProvider.isAuthenticated && authProvider.user != null) {
        _navigateToDashboard(authProvider.user!.role);
      } else {
        _navigateToAuth();
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (mounted) _navigateToAuth();
    }
  }

  Future<void> _markEmailVerified(User firebaseUser) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'role': UserRole.donor.name,
          'createdAt': DateTime.now().toIso8601String(),
          'isVerified': true,
          'emailVerified': true,
          'roleSelected': false,
        });
      } else {
        await docRef.update({'isVerified': true, 'emailVerified': true});
      }
    } catch (e) {
      debugPrint('_markEmailVerified error: $e');
    }
  }

  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // Start with sign in screen - it has links to sign up and phone auth
        builder: (context) => const SignInScreen(),
      ),
    );
  }

  void _navigateToDashboard(UserRole role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainWrapper(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                  Color(0xFF64B5F6),
                  Color(0xFF90CAF9),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Floating Background Elements
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Floating circles
                  Positioned(
                    top: 100 + (50 * _rotationAnimation.value),
                    left: 50 + (30 * _rotationAnimation.value),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200 + (30 * _rotationAnimation.value),
                    right: 80 + (40 * _rotationAnimation.value),
                    child: Transform.rotate(
                      angle: -_rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150 + (25 * _rotationAnimation.value),
                    left: 100 + (35 * _rotationAnimation.value),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 1.5 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main Content
          Center(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_animationController, _pulseController]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated App Icon with Pulse Effect
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(35),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 25,
                                        offset: const Offset(0, 15),
                                        spreadRadius: 5,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, -5),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    size: 70,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Animated App Name with Glow Effect
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [Colors.white, Colors.white70],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'FoodBridge',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'app_tagline'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),

                        // Enhanced Loading Indicator
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  // Inner ring
                                  const SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'preparing_experience'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Branding
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'powered_by_ai'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
