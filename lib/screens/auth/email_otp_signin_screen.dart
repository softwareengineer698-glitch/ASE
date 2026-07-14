import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main/main_wrapper.dart';
import 'sign_in_screen.dart';

/// Sign in via email verification link (passwordless / email OTP).
class EmailOtpSignInScreen extends StatefulWidget {
  const EmailOtpSignInScreen({super.key});

  @override
  State<EmailOtpSignInScreen> createState() => _EmailOtpSignInScreenState();
}

class _EmailOtpSignInScreenState extends State<EmailOtpSignInScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _linkSent = false;
  bool _isSending = false;
  bool _isChecking = false;
  int _cooldown = 60;
  Timer? _cooldownTimer;
  Timer? _pollTimer;
  String _sentEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final email = _emailController.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingEmailSignIn', email);

      final acs = ActionCodeSettings(
        url: 'https://CareCircle-chi-nine.vercel.app',
        handleCodeInApp: true,
        androidPackageName: 'com.example.CareCircle',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.example.CareCircle',
      );

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: acs,
      );

      _sentEmail = email;
      if (mounted) {
        setState(() { _linkSent = true; _isSending = false; });
        _startCooldown();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send link: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _startCooldown() {
    _cooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { if (_cooldown > 0) _cooldown--; });
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkSignIn(silent: true);
    });
  }

  Future<void> _checkSignIn({bool silent = false}) async {
    if (!silent) setState(() => _isChecking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;
        if (refreshed != null && refreshed.emailVerified) {
          _pollTimer?.cancel();
          await _onSignedIn(refreshed);
          return;
        }
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Not verified yet — please click the link in your email first.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (!silent && mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _onSignedIn(User firebaseUser) async {
    if (!mounted) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? _sentEmail,
          'role': UserRole.donor.name,
          'createdAt': DateTime.now().toIso8601String(),
          'isVerified': true,
          'emailVerified': true,
        });
      } else {
        await docRef.update({'isVerified': true, 'emailVerified': true});
      }
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Signed in successfully!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _linkSent ? _buildStep2(colorScheme) : _buildStep1(colorScheme),
        ),
      ),
    );
  }

  Widget _buildStep1(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.06),
        FadeInDown(child: Center(child: Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.email_rounded, size: 48, color: colorScheme.primary),
        ))),
        const SizedBox(height: 24),
        FadeInDown(delay: const Duration(milliseconds: 100),
          child: Text('Sign in with Email',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: colorScheme.primary),
            textAlign: TextAlign.center)),
        const SizedBox(height: 8),
        FadeInDown(delay: const Duration(milliseconds: 150),
          child: Text("Enter your email and we'll send you a sign-in link.",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center)),
        const SizedBox(height: 40),
        FadeInUp(delay: const Duration(milliseconds: 200),
          child: CustomTextField(
            controller: _emailController, label: 'email'.tr(),
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'email_required'.tr();
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim()))
                return 'invalid_email'.tr();
              return null;
            },
          )),
        const SizedBox(height: 28),
        FadeInUp(delay: const Duration(milliseconds: 250),
          child: CustomButton(
            text: _isSending ? 'Sending link...' : 'Send Sign-in Link',
            onPressed: _isSending ? null : _sendLink,
            isLoading: _isSending,
          )),
        const SizedBox(height: 20),
        Center(child: TextButton(
          onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SignInScreen())),
          child: Text('back_to_sign_in'.tr(),
              style: TextStyle(color: Colors.grey[600])),
        )),
      ]),
    );
  }

  Widget _buildStep2(ColorScheme colorScheme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
      FadeInDown(child: Center(child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.mark_email_unread_rounded, size: 52, color: colorScheme.primary),
      ))),
      const SizedBox(height: 24),
      FadeInDown(delay: const Duration(milliseconds: 100),
        child: Text('Check Your Email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold, color: colorScheme.primary),
          textAlign: TextAlign.center)),
      const SizedBox(height: 8),
      FadeInDown(delay: const Duration(milliseconds: 150),
        child: Text('Sign-in link sent to:',
            style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center)),
      const SizedBox(height: 4),
      FadeInDown(delay: const Duration(milliseconds: 170),
        child: Text(_sentEmail,
          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16),
          textAlign: TextAlign.center)),
      const SizedBox(height: 28),
      FadeInUp(delay: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Step('1', 'Open the email from CareCircle', colorScheme.primary),
            const SizedBox(height: 12),
            _Step('2', 'Tap the "Sign in to CareCircle" link', colorScheme.primary),
            const SizedBox(height: 12),
            _Step('3', 'Come back here — the app will sign you in automatically', colorScheme.primary),
          ]),
        )),
      const SizedBox(height: 28),
      FadeInUp(delay: const Duration(milliseconds: 250),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
          const SizedBox(width: 10),
          Text('Waiting for sign-in...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ])),
      const SizedBox(height: 28),
      FadeInUp(delay: const Duration(milliseconds: 300),
        child: CustomButton(
          text: _isChecking ? 'Checking...' : "I've Clicked the Link",
          onPressed: _isChecking ? null : () => _checkSignIn(),
          isLoading: _isChecking,
        )),
      const SizedBox(height: 16),
      FadeInUp(delay: const Duration(milliseconds: 350),
        child: Center(child: _cooldown > 0
          ? Text('Resend in ${_cooldown}s', style: TextStyle(color: Colors.grey[500]))
          : TextButton.icon(
              onPressed: _isSending ? null : _sendLink,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Resend Sign-in Link')))),
      const SizedBox(height: 12),
      Center(child: TextButton(
        onPressed: () => setState(() => _linkSent = false),
        child: Text('Use a different email', style: TextStyle(color: Colors.grey[600])),
      )),
      const SizedBox(height: 32),
    ]);
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  final Color color;
  const _Step(this.number, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 26, height: 26,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(number, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)))),
    ]);
  }
}
