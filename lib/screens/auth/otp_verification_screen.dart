import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/localized_error_text.dart';
import '../../widgets/custom_button.dart';
import '../main/main_wrapper.dart';
import 'sign_in_screen.dart';

/// Step 2 of phone auth: enter the 6-digit OTP and verify.
/// Also handles Android auto-verification (pass [autoVerifiedCredential]).
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final PhoneAuthCredential? autoVerifiedCredential;

  const OtpVerificationScreen({
    required this.phoneNumber,
    required this.verificationId,
    super.key,
    this.resendToken,
    this.autoVerifiedCredential,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // 6 individual controllers for the OTP boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSendingResend = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  late String _currentVerificationId;
  int? _currentResendToken;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentResendToken = widget.resendToken;
    _startCountdown();

    // If auto-verified, proceed directly
    if (widget.autoVerifiedCredential != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _handleAutoVerified());
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleAutoVerified() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = await authProvider
        .signInWithPhoneCredential(widget.autoVerifiedCredential!);
    if (!mounted) return;
    if (user != null) {
      await _afterVerification(authProvider, user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizedErrorText(
          authProvider.error,
          'phone_auth_failed',
        )),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('otp_too_short'.tr()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isVerifying = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = await authProvider.verifyOtp(
      verificationId: _currentVerificationId,
      smsCode: code,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (user != null) {
      await _afterVerification(authProvider, user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizedErrorText(authProvider.error, 'invalid_otp')),
        backgroundColor: Colors.red,
      ));
      // Clear OTP boxes on failure
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  Future<void> _afterVerification(
      AuthProvider authProvider, UserModel user) async {
    // Phone OTP is only used for sign-in — go straight to dashboard.
    // Role selection only happens during sign-up (email/password flow).
    _navigateToDashboard();
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isSendingResend) return;

    setState(() => _isSendingResend = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.sendOtp(
      phoneNumber: widget.phoneNumber,
      resendToken: _currentResendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _currentVerificationId = verificationId;
          _currentResendToken = resendToken;
          _isSendingResend = false;
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('otp_sent_to'.tr(namedArgs: {'phone': widget.phoneNumber})),
          backgroundColor: Colors.green,
        ));
      },
      onFailed: (error) {
        if (!mounted) return;
        setState(() => _isSendingResend = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedErrorText(error, 'phone_auth_failed')),
            backgroundColor: Colors.red,
          ),
        );
      },
      onAutoVerified: (credential) async {
        if (!mounted) return;
        final user = await authProvider.signInWithPhoneCredential(credential);
        if (!mounted) return;
        if (user != null) {
          await _afterVerification(authProvider, user);
        }
      },
    );
  }

  Future<UserRole?> _showRolePicker() {
    return showModalBottomSheet<UserRole>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SimpleRolePickerSheet(
        onSelected: (role) => Navigator.of(ctx).pop(role),
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
      (_) => false,
    );
  }

  Widget _buildOtpBox(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 54,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && v.isNotEmpty) {
            // Auto-submit when last digit entered
            _verify();
          }
        },
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              FadeInDown(
                child: Icon(Icons.sms_outlined,
                    size: 72, color: colorScheme.primary),
              ),
              const SizedBox(height: 20),

              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'enter_otp_title'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),

              FadeInDown(
                delay: const Duration(milliseconds: 150),
                child: Text(
                  'enter_otp_subtitle'
                      .tr(namedArgs: {'phone': widget.phoneNumber}),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // OTP input boxes
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, _buildOtpBox),
                ),
              ),
              const SizedBox(height: 32),

              Consumer<AuthProvider>(
                builder: (_, auth, __) => FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: CustomButton(
                    text: _isVerifying ? 'verifying'.tr() : 'verify_otp'.tr(),
                    onPressed:
                        (_isVerifying || auth.isLoading) ? null : _verify,
                    isLoading: _isVerifying || auth.isLoading,
                    fullWidth: true,
                    size: ButtonSize.large,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'resend_in'
                              .tr(namedArgs: {'seconds': '$_resendCountdown'}),
                          style: TextStyle(color: Colors.grey[500]),
                        )
                      : TextButton(
                          onPressed: _isSendingResend ? null : _resendOtp,
                          child: _isSendingResend
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text('resend_otp'.tr()),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                ),
                child: Text('or_use_email'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Simplified Role Picker (Donate / Receive only) ────────────────────────

class _SimpleRolePickerSheet extends StatefulWidget {
  final ValueChanged<UserRole> onSelected;

  const _SimpleRolePickerSheet({
    required this.onSelected,
  });

  @override
  State<_SimpleRolePickerSheet> createState() => _SimpleRolePickerSheetState();
}

class _SimpleRolePickerSheetState extends State<_SimpleRolePickerSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.swap_horiz_rounded,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'choose_your_role'.tr(),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'role_description'.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _RoleButton(
            title: 'donate'.tr(),
            icon: Icons.favorite_rounded,
            color: const Color(0xFFE53935),
            onTap: () => widget.onSelected(UserRole.donor),
          ),
          const SizedBox(height: 12),
          _RoleButton(
            title: 'receive'.tr(),
            icon: Icons.business_rounded,
            color: const Color(0xFF43A047),
            onTap: () => widget.onSelected(UserRole.ngo),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
