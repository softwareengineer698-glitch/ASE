import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';

import '../../widgets/custom_button.dart';
import '../main/main_wrapper.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Shown after account creation.
/// Instructs the user to click the verification link sent to their email.
/// Polls Firebase Auth every 3 seconds to detect when email is verified,
/// then marks the Firestore user doc as verified and shows the role picker.
class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String userName;

  const EmailOtpScreen({
    required this.email,
    required this.userName,
    super.key,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  Timer? _pollTimer;
  Timer? _resendCooldown;
  int _cooldownSeconds = 60;
  bool _isChecking = false;
  bool _resending = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startCooldown();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendCooldown?.cancel();
    super.dispose();
  }

  // ── Poll Firebase Auth every 3s to detect email verification ─────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkVerification(silent: true);
    });
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_verified) return;
    if (!silent) setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reload the user to get the latest emailVerified status
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        _pollTimer?.cancel();
        await _onEmailVerified(refreshed);
      } else if (!silent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Email not verified yet. Please click the link in your inbox.'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error checking verification: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (!silent && mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _onEmailVerified(User firebaseUser) async {
    if (!mounted) return;
    setState(() => _verified = true);

    // Mark user as verified in Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'isVerified': true,
        'emailVerified': true,
      });
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Email verified successfully!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Go directly to the app — no role selection needed
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
      (_) => false,
    );
  }

  // ── Resend verification email ─────────────────────────────────────────────

  void _startCooldown() {
    _cooldownSeconds = 60;
    _resendCooldown?.cancel();
    _resendCooldown =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_cooldownSeconds > 0) _cooldownSeconds--;
      });
    });
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0 || _resending) return;
    setState(() => _resending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Verification email resent to ${widget.email}'),
            backgroundColor: Colors.green,
          ));
          _startCooldown();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to resend: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _goBack() async {
    // Cancel polling before leaving
    _pollTimer?.cancel();
    _resendCooldown?.cancel();

    // Sign out the unverified account so the user can start fresh
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _goBack,
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              // Icon
              FadeInDown(
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mark_email_unread_rounded,
                        size: 52, color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Check Your Email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              FadeInDown(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'We sent a verification link to:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              FadeInDown(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // Instructions card
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Step(
                          number: '1',
                          text: 'Open the email from FoodBridge',
                          color: colorScheme.primary),
                      const SizedBox(height: 12),
                      _Step(
                          number: '2',
                          text: 'Click the "Verify Email" link',
                          color: colorScheme.primary),
                      const SizedBox(height: 12),
                      _Step(
                          number: '3',
                          text:
                              'Come back here — the app will detect it automatically',
                          color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Auto-checking indicator
              if (!_verified)
                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Waiting for verification...',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),

              if (_verified)
                FadeInUp(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Email verified!',
                          style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Manual "I've verified" button
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: CustomButton(
                  text: _isChecking
                      ? 'Checking...'
                      : "I've Verified My Email",
                  onPressed: _isChecking || _verified
                      ? null
                      : () => _checkVerification(),
                  isLoading: _isChecking,
                ),
              ),
              const SizedBox(height: 16),

              // Resend button
              FadeInUp(
                delay: const Duration(milliseconds: 350),
                child: Center(
                  child: _cooldownSeconds > 0
                      ? Text(
                          'Resend in ${_cooldownSeconds}s',
                          style: TextStyle(color: Colors.grey[500]),
                        )
                      : TextButton.icon(
                          onPressed: _resending ? null : _resendEmail,
                          icon: _resending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Resend Verification Email'),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Back to sign in
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (_) => false,
                  ),
                  child: Text('back_to_sign_in'.tr(),
                      style: TextStyle(color: Colors.grey[600])),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ), // closes Scaffold
    ); // closes PopScope
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String number;
  final String text;
  final Color color;

  const _Step({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text,
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ),
      ],
    );
  }
}
